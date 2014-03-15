//
//  PackageResourceResponse.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/15/14.
//  Copyright (c) 2014 The Readium Foundation. All rights reserved.
//

#import "PackageResourceResponse.h"
#import "PackageResourceServer.h"
#import "RDPackageResource.h"


@implementation PackageResourceResponse


- (UInt64)contentLength {
	return m_resource.contentLength;
}


- (id)initWithResource:(RDPackageResource *)resource {
	if (resource == nil) {
		return nil;
	}

	if (self = [super init]) {
		m_resource = resource;
	}

	return self;
}


- (BOOL)isDone {
	return m_offset == m_resource.contentLength;
}


- (UInt64)offset {
	return m_offset;
}


- (NSData *)readDataOfLength:(NSUInteger)length {
	NSData *data = nil;

	@synchronized ([PackageResourceServer resourceLock]) {
		data = [m_resource readDataOfLength:length];
	}

	if (data != nil) {
		m_offset += data.length;
	}

	return data;
}


- (void)setOffset:(UInt64)offset {
	m_offset = offset;

	@synchronized ([PackageResourceServer resourceLock]) {
		[m_resource setOffset:offset];
	}
}


@end
