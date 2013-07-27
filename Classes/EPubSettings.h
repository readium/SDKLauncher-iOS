//
//  EPubSettings.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSDKLauncherEPubSettingsDidChange;

@interface EPubSettings : NSObject

@property (nonatomic, assign) CGFloat columnGap;
@property (nonatomic, readonly) NSDictionary *dictionary;
@property (nonatomic, assign) CGFloat fontScale;
@property (nonatomic, assign) BOOL isSyntheticSpread;

+ (EPubSettings *)shared;

@end
