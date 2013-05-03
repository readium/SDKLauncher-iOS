//
//  RDContainer.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDContainer.h"
#import <ePub3/archive.h>
#import <ePub3/container.h>
#import "RDPackage.h"


@interface RDContainer() {
	@private ePub3::Container *m_container;
}

@end


@implementation RDContainer


@synthesize packages = m_packages;
@synthesize path = m_path;


- (void)dealloc {
	delete m_container;
	[m_packages release];
	[m_path release];
	[super dealloc];
}


+ (void)initialize {
	ePub3::Archive::Initialize();
}


- (id)initWithPath:(NSString *)path {
	if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_path = [path retain];
		m_container = new ePub3::Container(path.UTF8String);

		if (m_container == NULL) {
			[self release];
			return nil;
		}

		ePub3::Container::PackageList vec = m_container->Packages();
		m_packages = [[NSMutableArray alloc] initWithCapacity:4];

		for (auto i = vec.begin(); i != vec.end(); i++) {
			RDPackage *package = [[RDPackage alloc] initWithPackage:*i];
			[m_packages addObject:package];
			[package release];
		}
	}

	return self;
}


@end
