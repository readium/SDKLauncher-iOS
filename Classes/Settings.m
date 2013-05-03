//
//  Settings.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "Settings.h"


#define kKeyBookmarks @"ReadiumBookmarks"


@implementation Settings


- (NSDictionary *)bookmarks {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kKeyBookmarks];
}


- (void)setBookmarks:(NSDictionary *)bookmarks {
	if (bookmarks == nil) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyBookmarks];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:kKeyBookmarks];
	}
}


+ (Settings *)shared {
	static Settings *shared = nil;

	if (shared == nil) {
		shared = [[Settings alloc] init];
	}

	return shared;
}


@end
