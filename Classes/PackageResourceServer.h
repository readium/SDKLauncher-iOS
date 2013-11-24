//
//  PackageResourceServer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AQHTTPServer;
@class RDPackage;

@interface PackageResourceServer : NSObject {
	@private AQHTTPServer *m_httpServer;
	@private RDPackage *m_package;
}

@property (nonatomic, readonly) int port;

- (id)initWithPackage:(RDPackage *)package;

@end
