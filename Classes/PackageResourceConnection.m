//
//  PackageResourceConnection.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceConnection.h"
#import "PackageResourceResponseOperation.h"
#import "RDPackage.h"


static RDPackage *m_package = nil;


@implementation PackageResourceConnection


- (void)dealloc {
	[super dealloc];
}


- (AQHTTPResponseOperation *)responseOperationForRequest:(CFHTTPMessageRef)request {
	if (m_package == nil) {
		NSLog(@"The package is nil!");
		return nil;
	}

	NSURL *url = [(id)CFHTTPMessageCopyRequestURL(request) autorelease];

	if (url == nil) {
		return [super responseOperationForRequest:request];
	}

	NSString *fileSystemPath = [[NSBundle mainBundle].resourcePath
		stringByAppendingPathComponent:url.path];

	PackageResourceResponseOperation *op = nil;

	if ([[NSFileManager defaultManager] fileExistsAtPath:fileSystemPath]) {
		op = [[[PackageResourceResponseOperation alloc]
			initWithRequest:request
			socket:self.socket
			ranges:nil
			forConnection:self
			fileSystemPath:fileSystemPath] autorelease];
	}
	else {
		NSString *path = url.path;

		if (path != nil && [path hasPrefix:@"/"]) {
			path = [path substringFromIndex:1];
		}

		RDPackageResource *resource = [m_package resourceAtRelativePath:path];

		if (resource != nil) {
			NSString *rangeHeader = [(id)CFHTTPMessageCopyHeaderFieldValue(
				request, CFSTR("Range")) autorelease];

			NSArray *ranges = nil;

			if (rangeHeader != nil && rangeHeader.length > 0) {
				ranges = [self parseRangeRequest:rangeHeader withContentLength:resource.data.length];
			}

			op = [[[PackageResourceResponseOperation alloc]
				initWithRequest:request
				socket:self.socket
				ranges:ranges
				forConnection:self
				package:m_package
				packageResource:resource] autorelease];
		}
	}

	return op;
}


+ (void)setPackage:(RDPackage *)package {
	if (m_package != package) {
		[m_package release];
		m_package = [package retain];
	}
}


@end
