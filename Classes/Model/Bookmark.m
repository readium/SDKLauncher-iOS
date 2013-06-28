//
//  Bookmark.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "Bookmark.h"


#define kKeyCFI @"CFI"
#define kKeyContainerPath @"ContainerPath"
#define kKeyIDRef @"IDRef"
#define kKeyTitle @"Title"


@implementation Bookmark


@synthesize cfi = m_cfi;
@synthesize containerPath = m_containerPath;
@synthesize idref = m_idref;
@synthesize title = m_title;


- (void)dealloc {
	[m_cfi release];
	[m_containerPath release];
	[m_idref release];
	[m_title release];
	[super dealloc];
}


- (NSString *)description {
	return [@"Bookmark " stringByAppendingString:self.dictionary.description];
}


- (NSDictionary *)dictionary {
	return @{
		kKeyCFI : m_cfi,
		kKeyContainerPath : m_containerPath,
		kKeyIDRef : m_idref,
		kKeyTitle : m_title
	};
}


- (id)
	initWithCFI:(NSString *)cfi
	containerPath:(NSString *)containerPath
	idref:(NSString *)idref
	title:(NSString *)title
{
	if (cfi == nil ||
		cfi.length == 0 ||
		containerPath == nil ||
		containerPath.length == 0 ||
		idref == nil ||
		idref.length == 0)
	{
		[self release];
		return nil;
	}

	if (title == nil) {
		title = @"";
	}

	if (self = [super init]) {
		m_cfi = [cfi retain];
		m_containerPath = [containerPath retain];
		m_idref = [idref retain];
		m_title = [title retain];
	}

	return self;
}


- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		[self release];
		return nil;
	}

	return [self
		initWithCFI:[dictionary objectForKey:kKeyCFI]
		containerPath:[dictionary objectForKey:kKeyContainerPath]
		idref:[dictionary objectForKey:kKeyIDRef]
		title:[dictionary objectForKey:kKeyTitle]];
}


- (BOOL)isEqualToBookmark:(Bookmark *)bookmark {
	return
		bookmark != nil &&
		[bookmark.cfi isEqualToString:m_cfi] &&
		[bookmark.containerPath isEqualToString:m_containerPath] &&
		[bookmark.idref isEqualToString:m_idref] &&
		[bookmark.title isEqualToString:m_title];
}


@end
