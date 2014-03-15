//
//  BookmarkDatabase.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BookmarkDatabase.h"
#import "Bookmark.h"
#import "Settings.h"


@implementation BookmarkDatabase


- (void)addBookmark:(Bookmark *)bookmark {
	if (bookmark != nil) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:
			[Settings shared].bookmarks];
		NSMutableArray *array = [NSMutableArray arrayWithArray:
			[dict objectForKey:bookmark.containerPath]];
		[dict setObject:array forKey:bookmark.containerPath];
		[array addObject:bookmark.dictionary];
		[Settings shared].bookmarks = dict;
	}
}


- (NSArray *)bookmarksForContainerPath:(NSString *)containerPath {
	NSMutableArray *bookmarks = [NSMutableArray array];

	if (containerPath != nil && containerPath.length > 0) {
		for (NSDictionary *dict in [[Settings shared].bookmarks objectForKey:containerPath]) {
			Bookmark *b = [[Bookmark alloc] initWithDictionary:dict];

			if (b == nil) {
				NSLog(@"The bookmark is nil!");
			}
			else {
				[bookmarks addObject:b];
			}
		}
	}

	return bookmarks;
}


- (void)deleteBookmark:(Bookmark *)bookmark {
	if (bookmark == nil) {
		return;
	}

	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:
		[Settings shared].bookmarks];
	NSMutableArray *array = [NSMutableArray arrayWithArray:
		[dict objectForKey:bookmark.containerPath]];
	[dict setObject:array forKey:bookmark.containerPath];

	for (int i = 0; i < array.count; i++) {
		NSDictionary *d = [array objectAtIndex:i];
		Bookmark *b = [[Bookmark alloc] initWithDictionary:d];

		if (b == nil) {
			NSLog(@"The bookmark is nil!");
		}
		else if ([bookmark isEqualToBookmark:b]) {
			[array removeObjectAtIndex:i];
			[Settings shared].bookmarks = dict;
			return;
		}
	}
}


+ (BookmarkDatabase *)shared {
	static BookmarkDatabase *shared = nil;

	if (shared == nil) {
		shared = [[BookmarkDatabase alloc] init];
	}

	return shared;
}


@end
