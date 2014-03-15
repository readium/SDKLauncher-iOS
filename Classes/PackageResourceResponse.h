//
//  PackageResourceResponse.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/15/14.
//  Copyright (c) 2014 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@class RDPackageResource;

@interface PackageResourceResponse : NSObject <HTTPResponse> {
	@private UInt64 m_offset;
	@private RDPackageResource *m_resource;
}

- (id)initWithResource:(RDPackageResource *)resource;

@end
