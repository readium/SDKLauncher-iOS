//
//  RDPackageResource.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@class RDPackageResource;

@protocol RDPackageResourceDelegate

- (void)rdpackageResourceWillDeallocate:(RDPackageResource *)packageResource;

@end

@interface RDPackageResource : NSObject {
	@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
	@private NSData *m_data;
	@private id <RDPackageResourceDelegate> m_delegate;
	@private NSString *m_relativePath;
}

@property (nonatomic, readonly) void *byteStream;

// The content of the resource in its entirety.
@property (nonatomic, readonly) NSData *data;

// The relative path associated with this resource.
@property (nonatomic, readonly) NSString *relativePath;

// Creates an instance using the given C++ object.
- (id)
	initWithDelegate:(id <RDPackageResourceDelegate>)delegate
	byteStream:(void *)byteStream
	relativePath:(NSString *)relativePath;

@end
