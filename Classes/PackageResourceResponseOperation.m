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

@implementation PackageResourceResponseOperation {
    RDPackage * m_package;
    RDPackageResource * m_resource;
    NSString * m_filePath;
}

- (void)initialiseData:(RDPackage *)package resource:(RDPackageResource *)resource filePath:(NSString *)fileSystemPath
{
    if (m_package != nil)
    {
        [m_package release];
        m_package = nil;
    }
    m_package = package;
    [m_package retain];

    if (m_resource != nil)
    {
        [m_resource release];
        m_resource = nil;
    }
    m_resource = resource;
    [m_resource retain];

    if (m_filePath != nil)
    {
        [m_filePath release];
        m_filePath = nil;
    }
    m_filePath = fileSystemPath;
    [m_filePath retain];

    if (DEBUGLOG)
    {
        if (m_resource != nil)
        {
            NSLog(@"LOXHTTPResponseOperation: %@", m_resource.relativePath);
            NSLog(@"LOXHTTPResponseOperation: %ld", m_resource.bytesCount);
        }
        if (m_filePath != nil)
        {
            NSLog(@"LOXHTTPResponseOperation: %@ (FS)", m_filePath);
        }
        NSLog(@"LOXHTTPResponseOperation: %@", self);
    }
}

- (void)dealloc {
    if (DEBUGLOG)
    {
        NSLog(@"DEALLOC LOXHTTPResponseOperation");
        NSLog(@"DEALLOC LOXHTTPResponseOperation: %@", m_resource.relativePath);
        NSLog(@"DEALLOC LOXHTTPResponseOperation: %@", self);
    }

    if (m_package != nil)
    {
        [m_package release];
    }

    if (m_resource != nil)
    {
        [m_resource release];
    }

    if (m_filePath != nil)
    {
        [m_filePath release];
    }

    [super dealloc];
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
        NSLog(@"[%ld ... %ld] (%ld / %ld)", range.location, range.location+range.length-1, range.length, m_resource.bytesCount);
    }

    if (range.length == 0 || m_resource.bytesCount == 0)
    {
        NSLog(@"WTF?!");
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
