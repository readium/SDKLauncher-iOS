//
//  PackageResourceServer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOCK_BYTESTREAM(block) do {\
        dispatch_semaphore_wait(PackageResourceServer.byteStreamResourceLock, DISPATCH_TIME_FOREVER);\
        @try {\
            block();\
        } @finally {\
            dispatch_semaphore_signal(PackageResourceServer.byteStreamResourceLock);\
        }\
    } while (0);

@class AQHTTPServer;
@class RDPackage;

@interface PackageResourceServer : NSObject {
	@private AQHTTPServer *m_httpServer;
	@private RDPackage *m_package;
}

@property (nonatomic, readonly) int port;

- (id)initWithPackage:(RDPackage *)package;

+ (dispatch_semaphore_t) byteStreamResourceLock;

@end
