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
#import "RDPackageResource.h"
#import "PackageResourceServer.h"


static RDPackage *m_package = nil;


@implementation PackageResourceConnection


- (BOOL) supportsPipelinedRequests
{
    return YES;
}


- (AQHTTPResponseOperation *)responseOperationForRequest:(CFHTTPMessageRef)request {
	if (m_package == nil) {
		NSLog(@"The package is nil!");
		return nil;
	}

	NSURL *url = CFBridgingRelease(CFHTTPMessageCopyRequestURL(request));

	if (url == nil) {
		return [super responseOperationForRequest:request];
	}

	NSString *fileSystemPath = [[NSBundle mainBundle].resourcePath
		stringByAppendingPathComponent:url.path];

	PackageResourceResponseOperation *op = nil;

	if ([[NSFileManager defaultManager] fileExistsAtPath:fileSystemPath]) {
		op = [[PackageResourceResponseOperation alloc]
			initWithRequest:request
			socket:self.socket
			ranges:nil
			forConnection:self
			package:m_package
			resource:nil
			filePath:fileSystemPath];
	}
	else {
		NSString *path = url.path;

		if (path != nil && [path hasPrefix:@"/"]) {
			path = [path substringFromIndex:1];
		}

        __block RDPackageResource *resource =nil;
        LOCK_BYTESTREAM(^{
            resource = [m_package resourceAtRelativePath:path];
        });

		if (resource != nil) {
			NSString *rangeHeader = CFBridgingRelease(
				CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Range")));

			NSArray *ranges = nil;

			if (rangeHeader != nil && rangeHeader.length > 0) {
				ranges = [self parseRangeRequest:rangeHeader withContentLength:resource.bytesCount];
			}

			op = [[PackageResourceResponseOperation alloc]
				initWithRequest:request
				socket:self.socket
				ranges:ranges
				forConnection:self
				package:m_package
				resource:resource
				filePath:nil];
		}
	}

	return op;
}


+ (void)setPackage:(RDPackage *)package {
	m_package = package;
}


@end
