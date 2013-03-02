//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackageResource.h"
#import "archive.h"


@interface RDPackageResource() {
	@private ePub3::ArchiveReader *m_archiveReader;
}

@end


@implementation RDPackageResource


- (NSData *)createNextChunkByReading {
	ssize_t count = m_archiveReader->read(m_buffer, sizeof(m_buffer));
	return (count == 0) ? nil : [[NSData alloc] initWithBytes:m_buffer length:count];
}


- (NSData *)data {
	if (m_data == nil) {
		NSMutableData *md = [NSMutableData data];

		while (YES) {
			NSData *chunk = [self createNextChunkByReading];

			if (chunk != nil) {
				[md appendData:chunk];
				[chunk release];
			}
			else {
				break;
			}
		}

		m_data = [md retain];
	}

	return m_data;
}


- (void)dealloc {
	[m_data release];
	[super dealloc];
}


- (id)initWithArchiveReader:(void *)archiveReader {
	if (archiveReader == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_archiveReader = (ePub3::ArchiveReader *)archiveReader;
	}

	return self;
}


@end
