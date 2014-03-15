//
//  PackageResourceResponseOperation.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "AQHTTPResponseOperation.h"

@class RDPackage;
@class RDPackageResource;

@interface PackageResourceResponseOperation : AQHTTPResponseOperation <AQRandomAccessFile>

- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)socket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	package:(RDPackage *)package
	resource:(RDPackageResource *)resource
	filePath:(NSString *)filePath;

@end
