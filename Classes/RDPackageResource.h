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

//@protocol RDPackageResourceDelegate
//
//- (void)rdpackageResourceWillDeallocate:(RDPackageResource *)packageResource;
//
//@end

@interface RDPackageResource : NSObject {
	@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
	//@private id <RDPackageResourceDelegate> m_delegate;
	@private NSString *m_relativePath;
}

//@property (nonatomic, readonly) void *byteStream;
@property (nonatomic, readonly) int bytesCount;

// The relative path associated with this resource.
@property (nonatomic, readonly) NSString *relativePath;

//- (NSData *)createNextChunkByReading;

//- (NSData *)readAllDataChunks;

- (NSData *)createChunkByReadingRange:(NSRange)range package:(RDPackage *)package;


// Creates an instance using the given C++ object.
- (id)
	initWithByteStream://(id <RDPackageResourceDelegate>)delegate
	(void *)byteStream
	relativePath:(NSString *)relativePath
    pack:(RDPackage *)package;

@end
