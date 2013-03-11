//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceServer.h"
#import "AsyncSocket.h"
#import "PackageResourceCache.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


//
// PackageRequest
//


@interface PackageRequest : NSObject {
	@private NSDictionary *m_headers;
	@private RDPackageResource *m_resource;
	@private AsyncSocket *m_socket;
}

@property (nonatomic, retain) NSDictionary *headers;
@property (nonatomic, retain) RDPackageResource *resource;
@property (nonatomic, retain) AsyncSocket *socket;

@end

@implementation PackageRequest

@synthesize headers = m_headers;
@synthesize resource = m_resource;
@synthesize socket = m_socket;

- (void)dealloc {
	[m_headers release];
	[m_resource release];
	[m_socket release];
	[super dealloc];
}

@end


//
// PackageResourceServer
//


@interface PackageResourceServer()

@property (nonatomic, readonly) NSString *dateString;

@end


@implementation PackageResourceServer


- (NSString *)dateString {
	NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
	[fmt setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];
	[fmt setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	return [[fmt stringFromDate:[NSDate date]] stringByAppendingString:@" GMT"];
}


- (void)dealloc {
	NSArray *requests = [[NSArray alloc] initWithArray:m_requests];

	for (PackageRequest *request in requests) {
		// Disconnecting causes onSocketDidDisconnect to be called, which removes the request
		// from the array, which is why we iterate a copy of that array.
		[request.socket disconnect];
	}

	[requests release];

	[m_mainSocket release];
	[m_package release];
	[m_requests release];

	[super dealloc];
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_package = [package retain];
		m_requests = [[NSMutableArray alloc] init];

		m_mainSocket = [[AsyncSocket alloc] initWithDelegate:self];
		[m_mainSocket setRunLoopModes:@[ NSRunLoopCommonModes ]];

		NSError *error = nil;

		if (![m_mainSocket acceptOnPort:kSDKLauncherPackageResourceServerPort error:&error]) {
			NSLog(@"The main socket could not be created! %@", error);
			[self release];
			return nil;
		}
	}

	return self;
}


- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
	PackageRequest *request = [[[PackageRequest alloc] init] autorelease];
	request.socket = newSocket;
	[m_requests addObject:request];
}


- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[sock readDataWithTimeout:60 tag:0];
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if (data == nil || data.length == 0) {
		NSLog(@"The HTTP request data is missing!");
		[sock disconnect];
		return;
	}

	if (data.length >= 8192) {
		NSLog(@"The HTTP request data is unexpectedly large!");
		[sock disconnect];
		return;
	}

	NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
		autorelease];

	if (s == nil || s.length == 0) {
		NSLog(@"Could not read the HTTP request as a string!");
		[sock disconnect];
		return;
	}

	// Parse the HTTP method, path, and headers.

	NSMutableDictionary *headers = [NSMutableDictionary dictionary];
	PackageRequest *request = nil;
	BOOL firstLine = YES;

	for (NSString *line in [s componentsSeparatedByString:@"\r\n"]) {
		if (firstLine) {
			firstLine = NO;
			NSArray *tokens = [line componentsSeparatedByString:@" "];

			if (tokens.count != 3) {
				NSLog(@"The first line of the HTTP request does not have 3 tokens!");
				[sock disconnect];
				return;
			}

			NSString *method = [tokens objectAtIndex:0];

			if (![method isEqualToString:@"GET"]) {
				NSLog(@"The HTTP method is not GET!");
				[sock disconnect];
				return;
			}

			NSString *path = [tokens objectAtIndex:1];

			if (path.length == 0) {
				NSLog(@"The HTTP request path is missing!");
				[sock disconnect];
				return;
			}

			NSRange range = [path rangeOfString:@"/"];

			if (range.location != 0) {
				NSLog(@"The HTTP request path doesn't begin with a forward slash!");
				[sock disconnect];
				return;
			}

			range = [path rangeOfString:@"/" options:0 range:NSMakeRange(1, path.length - 1)];

			if (range.location == NSNotFound) {
				NSLog(@"The HTTP request path is incomplete!");
				[sock disconnect];
				return;
			}

			NSString *packageUUID = [path substringWithRange:NSMakeRange(1, range.location - 1)];

			if (![packageUUID isEqualToString:m_package.packageUUID]) {
				NSLog(@"The HTTP request has the wrong package UUID!");
				[sock disconnect];
				return;
			}

			path = [path substringFromIndex:NSMaxRange(range)];
			RDPackageResource *resource = [m_package resourceAtRelativePath:path isHTML:NULL];

			if (resource == nil) {
				NSLog(@"The package resource is missing!");
				[sock disconnect];
				return;
			}

			for (PackageRequest *currRequest in m_requests) {
				if (currRequest.socket == sock) {
					currRequest.headers = headers;
					currRequest.resource = resource;
					request = currRequest;
					break;
				}
			}

			if (request == nil) {
				NSLog(@"Could not find our request!");
				[sock disconnect];
				return;
			}
		}
		else {
			NSRange range = [line rangeOfString:@":"];

			if (range.location != NSNotFound) {
				NSString *key = [line substringToIndex:range.location];
				key = [key stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]];

				NSString *val = [line substringFromIndex:range.location + 1];
				val = [val stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]];

				[headers setObject:val forKey:key.lowercaseString];
			}
		}
	}

	int contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath:
		request.resource.relativePath];

	if (contentLength == 0) {
		[[PackageResourceCache shared] addResource:request.resource];
		contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath:
			request.resource.relativePath];
	}

	NSString *commonResponseHeaders = [NSString stringWithFormat:
		@"Date: %@\r\n"
		@"Server: PackageResourceServer\r\n"
		@"Accept-Ranges: bytes\r\n"
		@"Connection: close\r\n",
		self.dateString];

	// Handle requests that specify a 'Range' header, which iOS makes use of.  See:
	// http://developer.apple.com/library/ios/#documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6

	NSString *rangeToken = [headers objectForKey:@"range"];

	if (rangeToken != nil) {
		rangeToken = rangeToken.lowercaseString;

		if (![rangeToken hasPrefix:@"bytes="]) {
			NSLog(@"The requests's range doesn't begin with 'bytes='!");
			[sock disconnect];
			return;
		}

		rangeToken = [rangeToken substringFromIndex:6];

		NSArray *rangeValues = [rangeToken componentsSeparatedByString:@"-"];

		if (rangeValues == nil || rangeValues.count != 2) {
			NSLog(@"The requests's range doesn't have two values!");
			[sock disconnect];
			return;
		}

		NSString *s0 = [rangeValues objectAtIndex:0];
		NSString *s1 = [rangeValues objectAtIndex:1];

		s0 = [s0 stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		s1 = [s1 stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if (s0.length == 0 || s1.length == 0) {
			NSLog(@"The requests's range has a blank value!");
			[sock disconnect];
			return;
		}

		int p0 = s0.intValue;
		int p1 = s1.intValue;

		NSData *subdata = [[PackageResourceCache shared] dataAtRelativePath:
			request.resource.relativePath range:NSMakeRange(p0, p1 + 1 - p0)];

		if (subdata == nil || subdata.length != (p1 + 1 - p0)) {
			NSLog(@"The subdata is empty or has the wrong length!");
			[sock disconnect];
			return;
		}

		NSMutableString *ms = [NSMutableString stringWithCapacity:512];
		[ms appendString:@"HTTP/1.1 206 Partial Content\r\n"];
		[ms appendString:commonResponseHeaders];
		[ms appendFormat:@"Content-Length: %d\r\n", subdata.length];
		[ms appendFormat:@"Content-Range: bytes %d-%d/%d\r\n", p0, p1, contentLength];
		[ms appendString:@"\r\n"];

		[sock writeData:[ms dataUsingEncoding:NSUTF8StringEncoding] withTimeout:60 tag:0];
		[sock writeData:subdata withTimeout:60 tag:0];
	}
	else {
		NSData *subdata = [[PackageResourceCache shared] dataAtRelativePath:
			request.resource.relativePath];

		if (subdata == nil || subdata.length != contentLength) {
			NSLog(@"The subdata is empty or has the wrong length!");
			[sock disconnect];
			return;
		}

		NSMutableString *ms = [NSMutableString stringWithCapacity:512];
		[ms appendString:@"HTTP/1.1 200 OK\r\n"];
		[ms appendString:commonResponseHeaders];
		[ms appendFormat:@"Content-Length: %d\r\n", subdata.length];
		[ms appendString:@"\r\n"];

		[sock writeData:[ms dataUsingEncoding:NSUTF8StringEncoding] withTimeout:60 tag:0];
		[sock writeData:subdata withTimeout:60 tag:0];
	}

	[sock disconnectAfterWriting];
}


- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
}


- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	NSLog(@"The socket disconnected with an error! %@", err);
}


- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	for (PackageRequest *request in m_requests) {
		if (request.socket == sock) {
			[[sock retain] autorelease];
			[m_requests removeObject:request];
			return;
		}
	}
}


@end
