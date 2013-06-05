//
//  RDSpineItem.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDSpineItem.h"
#import <ePub3/manifest.h>
#import <ePub3/spine.h>


@interface RDSpineItem() {
	@private ePub3::SpineItem *m_spineItem;
}

@end


@implementation RDSpineItem


- (NSString *)baseHref {
	std::shared_ptr<ePub3::ManifestItem> manifestItem = m_spineItem->ManifestItem();

	if (manifestItem != NULL) {
		const ePub3::string s = manifestItem->BaseHref();
		return [NSString stringWithUTF8String:s.c_str()];
	}

	return nil;
}


- (void)dealloc {
	[super dealloc];
}


- (NSString *)idref {
	const ePub3::string s = m_spineItem->Idref();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (id)initWithSpineItem:(void *)spineItem {
	if (spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_spineItem = (ePub3::SpineItem *)spineItem;
	}

	return self;
}


@end
