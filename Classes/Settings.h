//
//  Settings.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

@property (nonatomic, strong) NSDictionary *bookmarks;
@property (nonatomic, assign) CGFloat columnGap;
@property (nonatomic, assign) CGFloat fontScale;
@property (nonatomic, assign) BOOL isSyntheticSpread;

+ (Settings *)shared;

@end
