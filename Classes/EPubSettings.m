//
//  EPubSettings.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "EPubSettings.h"
#import "Settings.h"


#define kKeyColumnGap @"columnGap"
#define kKeyFontScale @"fontSize"
#define kKeyIsSyntheticSpread @"isSyntheticSpread"


NSString * const kSDKLauncherEPubSettingsDidChange = @"SDKLauncherEPubSettingsDidChange";


@interface EPubSettings ()

- (void)postNotification;

@end


@implementation EPubSettings


- (CGFloat)columnGap {
	return [Settings shared].columnGap;
}


- (NSDictionary *)dictionary {
	return @{
		kKeyColumnGap : [NSNumber numberWithInt:round(self.columnGap)],
		kKeyFontScale : [NSNumber numberWithInt:round(100.0 * self.fontScale)],
		kKeyIsSyntheticSpread : [NSNumber numberWithBool:self.isSyntheticSpread],
	};
}


- (CGFloat)fontScale {
	return [Settings shared].fontScale;
}


- (BOOL)isSyntheticSpread {
	return [Settings shared].isSyntheticSpread;
}


- (void)postNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:
		kSDKLauncherEPubSettingsDidChange object:self];
}


- (void)setColumnGap:(CGFloat)columnGap {
	if ([Settings shared].columnGap != columnGap) {
		[Settings shared].columnGap = columnGap;
		[self postNotification];
	}
}


- (void)setFontScale:(CGFloat)fontScale {
	if ([Settings shared].fontScale != fontScale) {
		[Settings shared].fontScale = fontScale;
		[self postNotification];
	}
}


- (void)setIsSyntheticSpread:(BOOL)isSyntheticSpread {
	if ([Settings shared].isSyntheticSpread != isSyntheticSpread) {
		[Settings shared].isSyntheticSpread = isSyntheticSpread;
		[self postNotification];
	}
}


+ (EPubSettings *)shared {
	static EPubSettings *shared = nil;

	if (shared == nil) {
		shared = [[EPubSettings alloc] init];
	}

	return shared;
}


@end
