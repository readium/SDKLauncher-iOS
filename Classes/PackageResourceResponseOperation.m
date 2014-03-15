//
//  PackageResourceResponseOperation.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceResponseOperation.h"
#import "PackageResourceServer.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


@interface PackageResourceResponseOperation () {
	@private NSString *m_filePath;
	@private RDPackage *m_package;
	@private RDPackageResource *m_resource;
}

@end


@implementation PackageResourceResponseOperation


- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)socket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	package:(RDPackage *)package
	resource:(RDPackageResource *)resource
	filePath:(NSString *)filePath
{
	if (package == nil) {
		return nil;
	}

	if (self = [super
		initWithRequest:request
		socket:socket
		ranges:ranges
		forConnection:connection])
	{
		m_filePath = filePath;
		m_package = package;
		m_resource = resource;
	}

	return self;
}


- (NSUInteger) statusCodeForItemAtPath: (NSString *) rootRelativePath
{
    if (m_resource == nil)
    {
        return ( 200 );
    }

    NSString * method = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(_request));

    if (method != nil && [method caseInsensitiveCompare: @"DELETE"] == NSOrderedSame )
    {
        // Not Permitted
        return ( 403 );
    }
    else if ( _ranges != nil )
    {
        return ( 206 );
    }

    return ( 200 );
}

- (UInt64) sizeOfItemAtPath: (NSString *) rootRelativePath
{
    return [self length];
}

- (NSString *) etagForItemAtPath: (NSString *) path
{
    return nil;
}

- (NSInputStream *) inputStreamForItemAtPath: (NSString *) rootRelativePath
{
    if (m_resource == nil)
    {
        return [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:m_filePath]];
    }

    return nil;
}

- (id<AQRandomAccessFile>) randomAccessFileForItemAtPath: (NSString *) rootRelativePath
{
    //return [self autorelease];
    return self;
}

-(UInt64)length
{
    if (m_resource == nil)
    {
        //if ([[NSFileManager defaultManager] fileExistsAtPath:m_filePath])
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:m_filePath error:nil];
        return (attrs == nil) ? 0 : attrs.fileSize;
    }

    return m_resource.bytesCount;
}

- (NSData *) readDataFromByteRange: (DDRange) range
{
	if (m_resource == nil)
	{
		NSLog(@"NOT READY?!");
		return [NSData data];
	}

	if (DEBUGLOG)
	{
		NSLog(@"[%llu ... %llu] (%llu / %d)",
			range.location, range.location + range.length - 1, range.length, m_resource.bytesCount);
	}

	if (range.length == 0 || m_resource.bytesCount == 0)
	{
		NSLog(@"The range length is zero, or the resource bytes count is zero!");
		return [NSData data];
	}

    __block NSData * result = nil;

    if (DEBUGLOG)
    {
        NSLog(@"LOCK readDataFromByteRange: %@", self);
    }

    LOCK_BYTESTREAM(^{
        result = [m_resource createChunkByReadingRange:NSRangeFromDDRange(range) package:m_package];
    });

    if (DEBUGLOG)
    {
        NSLog(@"un-LOCK readDataFromByteRange: %@", self);
    }

    //result = [NSData data];
    //[result autorelease];

    return result;
}


@end
