//
//  PackageResourceConnection.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceConnection.h"
#import "PackageDataResponse.h"
#import "PackageResourceResponse.h"
#import "PackageResourceServer.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


static RDPackage *m_package = nil;


@implementation PackageResourceConnection


- (NSObject <HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	if (m_package == nil ||
		method == nil ||
		![method isEqualToString:@"GET"] ||
		path == nil ||
		path.length == 0)
	{
		return nil;
	}

	if (path != nil && [path hasPrefix:@"/"]) {
		path = [path substringFromIndex:1];
	}

    NSObject <HTTPResponse> *response = nil;

	// Synchronize using a process-level lock to guard against multiple threads accessing a
	// resource byte stream, which may lead to instability.

	@synchronized ([PackageResourceServer resourceLock]) {
		RDPackageResource *resource = [m_package resourceAtRelativePath:path];

		if (resource == nil) {
			NSLog(@"No resource found! (%@)", path);
		}
		else if (resource.contentLength < 1000000) {

			// This resource is small enough that we can just fetch the entire thing in memory,
			// which simplifies access into the byte stream.  Adjust the threshold to taste.

			NSData *data = resource.data;

			if (data != nil) {
				PackageDataResponse *dataResponse = [[PackageDataResponse alloc] initWithData:data];
                if (resource.mimeType) {
                    dataResponse.contentType = resource.mimeType;
                }
                response = dataResponse;
			}
		}
		else {
			PackageResourceResponse *resourceResponse = [[PackageResourceResponse alloc] initWithResource:resource];
            response = resourceResponse;
		}
	}

	return response;
}


+ (void)setPackage:(RDPackage *)package {
	m_package = package;
}


@end
