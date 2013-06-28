//
//  PackageResourceServer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AsyncSocket;
@class RDPackage;

@interface PackageResourceServer : NSObject {
	@private AsyncSocket *m_mainSocket;
	@private RDPackage *m_package;
	@private NSMutableArray *m_requests;
}

- (id)initWithPackage:(RDPackage *)package;

@end
