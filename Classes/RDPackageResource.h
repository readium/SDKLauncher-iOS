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

- (void)RDPackageResourceWillDeallocate:(RDPackageResource *)packageResource;

@end

@interface RDPackageResource : NSObject {
	@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
	@private NSData *m_data;
	@private id <RDPackageResourceDelegate> m_delegate;
	@private NSString *m_relativePath;
}

@property (nonatomic, readonly) void *archiveReader;

// The content of the resource in its entirety.  If you call this, don't call
// createNextChunkByReading.
@property (nonatomic, readonly) NSData *data;

// The relative path associated with this resource.
@property (nonatomic, readonly) NSString *relativePath;

// The next chunk of data for the resource, or nil if we have finished reading all chunks.  If
// you call this, don't call the data property.
- (NSData *)createNextChunkByReading;

// Creates an instance using the given C++ object.
- (id)
	initWithDelegate:(id <RDPackageResourceDelegate>)delegate
	archiveReader:(void *)archiveReader
	relativePath:(NSString *)relativePath;

@end
