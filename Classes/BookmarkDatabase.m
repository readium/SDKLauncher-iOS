//
//  BookmarkDatabase.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

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
