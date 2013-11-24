//
//  PackageResourceResponseOperation.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceResponseOperation.h"
#import "PackageResourceCache.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


@implementation PackageResourceResponseOperation


- (void)dealloc {
	[m_fileSystemPath release];
	[m_package release];
	[m_packageResource release];
	[super dealloc];
}


- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)aSocket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	fileSystemPath:(NSString *)fileSystemPath
{
	if (fileSystemPath == nil) {
		NSLog(@"The file system path is nil!");
		[self release];
		return nil;
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath:fileSystemPath]) {
		NSLog(@"Path '%@' does not exist!", fileSystemPath);
		[self release];
		return nil;
	}

	if (self = [super
		initWithRequest:request
		socket:aSocket
		ranges:ranges
		forConnection:connection])
	{
		m_fileSystemPath = [fileSystemPath retain];
	}

	return self;
}


- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)aSocket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	package:(RDPackage *)package
	packageResource:(RDPackageResource *)packageResource
{
	if (package == nil || packageResource == nil) {
		[self release];
		return nil;
	}

	if (self = [super
		initWithRequest:request
		socket:aSocket
		ranges:ranges
		forConnection:connection])
	{
		m_package = [package retain];
		m_packageResource = [packageResource retain];
	}

	return self;
}


- (NSInputStream *)inputStreamForItemAtPath:(NSString *)rootRelativePath {
	if (m_fileSystemPath != nil && m_fileSystemPath.length > 0) {
		return [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:m_fileSystemPath]];
	}

	if (_ranges != nil) {
		//!@# handle this
	}

	if (m_packageResource != nil) {
		return [NSInputStream inputStreamWithData:m_packageResource.data];
	}

	return nil;
}


- (NSData *)readDataFromByteRange:(DDRange)range {
	//!@# handle range requests
	return nil;
}


- (UInt64)sizeOfItemAtPath:(NSString *)rootRelativePath {
	if (m_fileSystemPath != nil && m_fileSystemPath.length > 0) {
		NSDictionary *attrs = [[NSFileManager defaultManager]
			attributesOfItemAtPath:m_fileSystemPath error:nil];
		return (attrs == nil) ? 0 : attrs.fileSize;
	}

	if (_ranges != nil) {
		if ([rootRelativePath hasPrefix:@"/"]) {
			rootRelativePath = [rootRelativePath substringFromIndex:1];
		}

		PackageResourceCache *cache = [PackageResourceCache shared];
		return [cache contentLengthAtRelativePath:rootRelativePath];
	}

	if (m_packageResource != nil) {
		return m_packageResource.data.length;
	}

	return 0;
}


- (NSUInteger)statusCodeForItemAtPath:(NSString *)rootRelativePath {
	NSString *method = [(id)CFHTTPMessageCopyRequestMethod(_request) autorelease];

	if (method == nil || [method caseInsensitiveCompare:@"GET"] != NSOrderedSame) {
		return 403;
	}

	if (_ranges != nil) {
		return 206;
	}

	return 200;
}


@end
