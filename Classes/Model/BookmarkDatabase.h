//
//  BookmarkDatabase.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Bookmark;

@interface BookmarkDatabase : NSObject

- (void)addBookmark:(Bookmark *)bookmark;
- (NSArray *)bookmarksForContainerPath:(NSString *)containerPath;
- (void)deleteBookmark:(Bookmark *)bookmark;
+ (BookmarkDatabase *)shared;

@end
