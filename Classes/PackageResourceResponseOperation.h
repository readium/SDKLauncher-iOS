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

@interface PackageResourceResponseOperation : AQHTTPResponseOperation {
	@private NSString *m_fileSystemPath;
	@private RDPackage *m_package;
	@private RDPackageResource *m_packageResource;
}

- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)aSocket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	fileSystemPath:(NSString *)fileSystemPath;

- (id)
	initWithRequest:(CFHTTPMessageRef)request
	socket:(AQSocket *)aSocket
	ranges:(NSArray *)ranges
	forConnection:(AQHTTPConnection *)connection
	package:(RDPackage *)package
	packageResource:(RDPackageResource *)packageResource;

@end
