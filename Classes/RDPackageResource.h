//
//  RDPackageResource.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface RDPackageResource : NSObject {
	@private UInt8 m_buffer[2048];
	@private NSData *m_data;
}

// The content of the resource in its entirety.  If you call this, don't call
// createNextChunkByReading.
@property (nonatomic, readonly) NSData *data;

// The next chunk of data for the resource, or nil if we have finished reading all chunks.  If
// you call this, don't call the data property.
- (NSData *)createNextChunkByReading;

// Creates an instance using the given C++ object.
- (id)initWithArchiveReader:(void *)archiveReader;

@end
