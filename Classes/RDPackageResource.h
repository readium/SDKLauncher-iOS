//
//  RDPackageResource.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@class RDPackage;
@class RDPackageResource;

@protocol RDPackageResourceDelegate

- (void)rdpackageResourceWillDeallocate:(RDPackageResource *)packageResource;

@end

@interface RDPackageResource : NSObject {
	@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
	@private __weak id <RDPackageResourceDelegate> m_delegate;
	@private NSString *m_relativePath;
}

@property (nonatomic, readonly) int bytesCount;
@property (nonatomic, readonly) void *byteStream;

// The relative path associated with this resource.
@property (nonatomic, readonly) NSString *relativePath;

- (NSData *)createChunkByReadingRange:(NSRange)range package:(RDPackage *)package;

- (id)
	initWithDelegate:(id <RDPackageResourceDelegate>)delegate
	byteStream:(void *)byteStream
	package:(RDPackage *)package
	relativePath:(NSString *)relativePath;

@end
