//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackageResource.h"
#import <ePub3/utilities/byte_stream.h>


@interface RDPackageResource() {
	@private ePub3::ByteStream *m_byteStream;
}

- (NSData *)createNextChunkByReading;

@end


@implementation RDPackageResource


@synthesize byteStream = m_byteStream;
@synthesize relativePath = m_relativePath;


- (NSData *)createNextChunkByReading {
	ePub3::ByteStream::size_type count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));
	return (count == 0) ? nil : [[NSData alloc] initWithBytes:m_buffer length:count];
}


- (NSData *)data {
	if (m_data == nil) {

		//
		// There are some issues when reading multiple byte streams in parallel. For now,
		// synchronize all byte stream reading (using a class object).
		//

		@synchronized ([RDPackageResource class]) {
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
		}
	}

	return m_data;
}


- (void)dealloc {
	[m_delegate rdpackageResourceWillDeallocate:self];

	[m_data release];
	[m_relativePath release];

	[super dealloc];
}


- (id)
	initWithDelegate:(id <RDPackageResourceDelegate>)delegate
	byteStream:(void *)byteStream
	relativePath:(NSString *)relativePath
{
	if (byteStream == nil || relativePath == nil || relativePath.length == 0) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_byteStream = (ePub3::ByteStream *)byteStream;
		m_delegate = delegate;
		m_relativePath = [relativePath retain];
	}

	return self;
}


@end
