//
//  Bookmark.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Bookmark : NSObject {
	@private NSString *m_cfi;
	@private NSString *m_containerPath;
	@private NSString *m_idref;
	@private NSString *m_title;
}

@property (nonatomic, readonly) NSString *cfi;
@property (nonatomic, readonly) NSString *containerPath;
@property (nonatomic, readonly) NSDictionary *dictionary;
@property (nonatomic, readonly) NSString *idref;
@property (nonatomic, readonly) NSString *title;

- (id)
	initWithCFI:(NSString *)cfi
	containerPath:(NSString *)containerPath
	idref:(NSString *)idref
	title:(NSString *)title;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isEqualToBookmark:(Bookmark *)bookmark;

@end
