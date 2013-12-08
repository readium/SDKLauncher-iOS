//
//  AQHTTPConnection.m
//  SimpleHTTPServer
//
//  Created by Jim Dovey on 12-04-25.
//  Copyright (c) 2012 Jim Dovey. All rights reserved.
//

#import "AQHTTPConnection.h"
#import "AQHTTPConnection_PrivateInternal.h"
#import "AQHTTPServer.h"
#import "AQSocket.h"
#import "AQSocketReader.h"
#import "AQHTTPFileResponseOperation.h"
#import "DDRange.h"
#import "DDNumber.h"


#define LOCK_ME(block) do {\
        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);\
        @try {\
            block();\
        } @finally {\
            dispatch_semaphore_signal(_lock);\
        }\
    } while (0);

@interface AQHTTPConnection ()
- (void) _setEventHandlerOnSocket;
- (void) _handleIncomingData: (AQSocketReader *) reader;
- (void) _socketDisconnected;
- (void) _socketErrorOccurred: (NSError *) error;
@end

@implementation AQHTTPConnection
{
    // a serial, cancellable queue
    NSOperationQueue *_requestQ;
    
    AQSocket * _socket;
    NSURL * _documentRoot;
    CFHTTPMessageRef _incomingMessage;
    
    NSTimer *   _idleDisconnectionTimer;
    dispatch_semaphore_t _lock;
    
    AQHTTPServer * __maybe_weak _server;
}

@synthesize delegate, documentRoot=_documentRoot, socket=_socket, server=_server;

- (id) initWithSocket: (AQSocket *) aSocket documentRoot: (NSURL *) documentRoot forServer: (AQHTTPServer *) server
{
    self = [super init];
    if ( self == nil )
        return ( nil );
    
    _documentRoot = [documentRoot copy];
    _server = server;       // weak/unsafe reference
    
    _requestQ = [NSOperationQueue new];
    _requestQ.maxConcurrentOperationCount = 1;

    // create a critical section lock
    _lock = dispatch_semaphore_create(1);
    
    // don't install the event handler until we've got the queue ready: the event handler might be called immediately if data has already arrived.
    _socket = aSocket;
#if USING_MRR
    [_socket retain];
#endif
    
    // we need to wait for subclass initialization to complete before we install our event handlers
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self _setEventHandlerOnSocket];
    });
    
    return ( self );
}

- (void) dealloc
{
    if ( _incomingMessage != NULL )
        CFRelease(_incomingMessage);
    _socket.eventHandler = nil;

#if DISPATCH_USES_ARC == 0
    if ( _lock != NULL )
    {
        //dispatch_semaphore_signal(_lock);
        dispatch_release(_lock);
        _lock = NULL;
    }
#endif

#if USING_MRR
    [_documentRoot release];
    [_socket release];
    [_requestQ release];
    [super dealloc];
#endif
}

- (void) close
{
    [_requestQ cancelAllOperations];
    [_socket close];
    _socket.eventHandler = nil;
#if USING_MRR
    [_socket release];
#endif
    _socket = nil;
    
    [self.delegate connectionDidClose: self];
}

- (void) setDocumentRoot: (NSURL *) documentRoot
{
    dispatch_block_t setterBody = ^{
#if USING_MRR
        NSURL * newValue = [documentRoot copy];
        NSURL * oldValue = _documentRoot;
        _documentRoot = newValue;
        [oldValue release];
#else
        _documentRoot = [documentRoot copy];
#endif
        [self documentRootDidChange];
    };
    
    if ( [_requestQ operationCount] != 0 )
    {
        // wait until the in-flight operations have completed before updating the value
        [[[_requestQ operations] lastObject] setCompletionBlock: setterBody];
        return;
    }
    
    // otherwise, we can go ahead and do it now
    setterBody();
}

- (void) _setEventHandlerOnSocket
{
    __maybe_weak AQHTTPConnection * weakSelf = self;
    _socket.eventHandler = ^(AQSocketEvent event, id info){
#if DEBUGLOG
        NSLog(@"Socket event occurred: %d (%@)", event, info);
#endif
        AQHTTPConnection * strongSelf = weakSelf;
        switch ( event )
        {
            case AQSocketEventDataAvailable:
#if DEBUGLOG
                NSLog(@"AQSocketEventDataAvailable");
#endif
                [strongSelf _handleIncomingData: info];
                break;
                
            case AQSocketEventDisconnected:
#if DEBUGLOG
                NSLog(@"AQSocketEventDisconnected");
#endif
                [strongSelf _socketDisconnected];
                break;
                
            case AQSocketErrorEncountered:
#if DEBUGLOG
                NSLog(@"AQSocketErrorEncountered");
#endif
                [strongSelf _socketErrorOccurred: info];
                break;
                
            default:
                break;
        }
    };
}

- (BOOL) supportsPipelinedRequests
{
    return ( YES );
}

- (NSArray *) parseRangeRequest:(NSString *)rangeHeader withContentLength:(UInt64)contentLength
{
//	HTTPLogTrace();
	
	// Examples of byte-ranges-specifier values (assuming an entity-body of length 10000):
	// 
	// - The first 500 bytes (byte offsets 0-499, inclusive):  bytes=0-499
	// 
	// - The second 500 bytes (byte offsets 500-999, inclusive): bytes=500-999
	// 
	// - The final 500 bytes (byte offsets 9500-9999, inclusive): bytes=-500
	// 
	// - Or bytes=9500-
	// 
	// - The first and last bytes only (bytes 0 and 9999):  bytes=0-0,-1
	// 
	// - Several legal but not canonical specifications of the second 500 bytes (byte offsets 500-999, inclusive):
	// bytes=500-600,601-999
	// bytes=500-700,601-999
	//
	
	NSRange eqsignRange = [rangeHeader rangeOfString:@"="];
	
	if(eqsignRange.location == NSNotFound) return nil;
	
	NSUInteger tIndex = eqsignRange.location;
	NSUInteger fIndex = eqsignRange.location + eqsignRange.length;
	
	NSMutableString *rangeType  = [[rangeHeader substringToIndex:tIndex] mutableCopy];
	NSMutableString *rangeValue = [[rangeHeader substringFromIndex:fIndex] mutableCopy];
#if USING_MRR
    [rangeType autorelease];
    [rangeValue autorelease];
#endif
	
	CFStringTrimWhitespace((__bridge CFMutableStringRef)rangeType);
	CFStringTrimWhitespace((__bridge CFMutableStringRef)rangeValue);
	
	if([rangeType caseInsensitiveCompare:@"bytes"] != NSOrderedSame) return nil;
	
	NSArray *rangeComponents = [rangeValue componentsSeparatedByString:@","];
	
	if([rangeComponents count] == 0) return nil;
	
	NSMutableArray * ranges = [[NSMutableArray alloc] initWithCapacity:[rangeComponents count]];
#if USING_MRR
    [ranges autorelease];
#endif
	
	// Note: We store all range values in the form of DDRange structs, wrapped in NSValue objects.
	// Since DDRange consists of UInt64 values, the range extends up to 16 exabytes.
	
	NSUInteger i;
	for (i = 0; i < [rangeComponents count]; i++)
	{
		NSString *rangeComponent = [rangeComponents objectAtIndex:i];
		
		NSRange dashRange = [rangeComponent rangeOfString:@"-"];
		
		if (dashRange.location == NSNotFound)
		{
			// We're dealing with an individual byte number
			
			UInt64 byteIndex;
			if(![NSNumber parseString:rangeComponent intoUInt64:&byteIndex]) return nil;
			
			if(byteIndex >= contentLength) return nil;
			
			[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(byteIndex, 1)]];
		}
		else
		{
			// We're dealing with a range of bytes
			
			tIndex = dashRange.location;
			fIndex = dashRange.location + dashRange.length;
			
			NSString *r1str = [rangeComponent substringToIndex:tIndex];
			NSString *r2str = [rangeComponent substringFromIndex:fIndex];
			
			UInt64 r1, r2;
			
			BOOL hasR1 = [NSNumber parseString:r1str intoUInt64:&r1];
			BOOL hasR2 = [NSNumber parseString:r2str intoUInt64:&r2];
			
			if (!hasR1)
			{
				// We're dealing with a "-[#]" range
				// 
				// r2 is the number of ending bytes to include in the range
				
				if(!hasR2) return nil;
				if(r2 > contentLength) return nil;
				
				UInt64 startIndex = contentLength - r2;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(startIndex, r2)]];
			}
			else if (!hasR2)
			{
				// We're dealing with a "[#]-" range
				// 
				// r1 is the starting index of the range, which goes all the way to the end
				
				if(r1 >= contentLength) return nil;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(r1, contentLength - r1)]];
			}
			else
			{
				// We're dealing with a normal "[#]-[#]" range
				// 
				// Note: The range is inclusive. So 0-1 has a length of 2 bytes.
				
				if(r1 > r2) return nil;
				if(r2 >= contentLength) return nil;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(r1, r2 - r1 + 1)]];
			}
		}
	}
	
	if([ranges count] == 0) return nil;
    
    // NB: no sorting or combining-- that's being done later
	
	return [NSArray arrayWithArray: ranges];
}

- (void) _maybeInstallIdleTimer
{
    LOCK_ME(^{

    if ( [_requestQ operationCount] == 0 &&  _idleDisconnectionTimer == nil )
    {
        _idleDisconnectionTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow: 2.0]
                                                           interval: 2.0
                                                             target: self
                                                           selector: @selector(_checkIdleTimer:)
                                                           userInfo: nil
                                                            repeats: NO];
        [[NSRunLoop mainRunLoop] addTimer: _idleDisconnectionTimer forMode: NSRunLoopCommonModes];
    }

    });
}

- (void) _checkIdleTimer: (NSTimer *) timer
{
    if ( [_requestQ operationCount] != 0 )
        return;

#if DEBUGLOG
    NSLog(@"_checkIdleTimer: %@", self);
#endif

    // disconnect due to under-utilization
    //[self close];
    [self _socketDisconnected];
}

- (AQHTTPResponseOperation *) responseOperationForRequest: (CFHTTPMessageRef) request
{
#if DEBUGLOG
    NSLog(@"DEFAULT responseOperationForRequest (FILE)");
#endif

    NSString * path = [(NSURL *)CFBridgingRelease(CFHTTPMessageCopyRequestURL(request)) path];

#if DEBUGLOG
    NSLog(@"path: %@", path);
#endif

    if (path == nil)
    {
        return nil;
    }

    NSString * rangeHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Range")));
    NSArray * ranges = nil;
    if ( rangeHeader != nil )
    {
#if DEBUGLOG
        NSLog(@"rangeHeader: %@", rangeHeader);
#endif
        path = [[_documentRoot path] stringByAppendingPathComponent: path];
        ranges = [self parseRangeRequest: rangeHeader withContentLength: [[[NSFileManager defaultManager] attributesOfItemAtPath: path error: NULL] fileSize]];
    }
    
    // the best thing about this approach? It works with pipelining!
    AQHTTPFileResponseOperation * op = [[AQHTTPFileResponseOperation alloc] initWithRequest: request socket: _socket ranges: ranges forConnection: self];
#if USING_MRR
    [op autorelease];
#endif
    return ( op );
}

- (void) _handleIncomingData: (AQSocketReader *) reader
{
    NSUInteger readerLength = reader.length;

#if DEBUGLOG
    NSLog(@"Data arriving on %p; length=%lu", self, (unsigned long)readerLength);
#endif
    
    CFHTTPMessageRef msg = NULL;
    if ( _incomingMessage != NULL )
    {
#if DEBUGLOG
        NSLog(@"CFHTTPMessageRef _incomingMessage RETAIN");
#endif
        msg = (CFHTTPMessageRef)CFRetain(_incomingMessage);
    }
    else
    {
#if DEBUGLOG
        NSLog(@"CFHTTPMessageCreateEmpty");
#endif
        msg = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
    }
    
    NSData * data = [reader readBytes: reader.length];
    if (data == nil || readerLength <= 0 || [data length] <= 0 || !CFHTTPMessageAppendBytes(msg, [data bytes], [data length]))
    {
        NSLog(@"------ !CFHTTPMessageAppendBytes !!! %ld", (unsigned long)[data length]);
    }
    else
    {
        if ( CFHTTPMessageIsHeaderComplete(msg) )
        {

    #if DEBUGLOG
            NSString * httpVersion = CFBridgingRelease(CFHTTPMessageCopyVersion(msg));
            NSString * httpMethod  = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(msg));
            NSURL * url = CFBridgingRelease(CFHTTPMessageCopyRequestURL(msg));
            NSDictionary * headers = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(msg));
            NSData * body = CFBridgingRelease(CFHTTPMessageCopyBody(msg));

            NSMutableString * debugStr = [NSMutableString string];
            [debugStr appendFormat: @"%@ %@ \"%@\"\n", httpVersion, httpMethod, [url absoluteString]];
            [headers enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
                [debugStr appendFormat: @"%@: %@\n", key, obj];
            }];
            if ( [body length] != 0 )
            {
                NSString * bodyStr = [[NSString alloc] initWithData: body encoding: NSUTF8StringEncoding];
                [debugStr appendFormat: @"\n%@\n", bodyStr];
    #if USING_MRR
                [bodyStr release];
    #endif
            }

            NSLog(@"Incoming request:\n%@", debugStr);
    #endif

            if ( _incomingMessage == msg && _incomingMessage != NULL )
            {
    #if DEBUGLOG
                NSLog(@"CFRelease _incomingMessage");
    #endif
                CFRelease(_incomingMessage);
                _incomingMessage = NULL;
            }

            AQHTTPResponseOperation * op = [self responseOperationForRequest: msg];
            if ( op != nil )
            {
    #if DEBUGLOG
                NSLog(@"AQHTTPResponseOperation");
    #endif
                [op setCompletionBlock: ^{ [self _maybeInstallIdleTimer]; }];
                LOCK_ME(^{

                if ( [_idleDisconnectionTimer isValid] )
                {
    #if DEBUGLOG
                    NSLog(@"_idleDisconnectionTimer");
    #endif
                    [_idleDisconnectionTimer invalidate];
    #if USING_MRR
                    [_idleDisconnectionTimer release];
    #endif
                    _idleDisconnectionTimer = nil;
                }

                [_requestQ addOperation: op];

                });
            }
            else
            {
    #if DEBUGLOG
                NSLog(@"!! AQHTTPResponseOperation");
    #endif
                // disconnect
                //[self close];
                [self _socketDisconnected];
            }
        }
        else
        {
    #if DEBUGLOG
            NSLog(@"!CFHTTPMessageIsHeaderComplete _incomingMessage NEW ");
    #endif
            _incomingMessage = (CFHTTPMessageRef)CFRetain(msg);
        }
    }
    
    if (msg != NULL)
    {
        CFRelease(msg);
    }
}

- (void) _socketDisconnected
{
#if USING_MRR
    AQSocket * tmp = [_socket retain];
    [self close];
    [tmp release];
#else
    [self close];
#endif
}

- (void) _socketErrorOccurred: (NSError *) error
{
#if DEBUGLOG
    NSLog(@"Error occurred on socket: %@", error);
#endif
#if USING_MRR
    AQSocket * tmp = [_socket retain];
    [self close];
    [tmp release];
#else
    [self close];
#endif
}

@end
