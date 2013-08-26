//
//  Settings.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "Settings.h"


#define kKeyBookmarks @"SDKLauncherBookmarks"
#define kKeyColumnGap @"SDKLauncherColumnGap"
#define kKeyFontScale @"SDKLauncherFontScale"
#define kKeyIsSyntheticSpread @"SDKLauncherIsSyntheticSpread"


@interface Settings ()

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (CGFloat)cgFloatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue;
- (void)setCGFloat:(CGFloat)value forKey:(NSString *)key;

@end


@implementation Settings


- (NSDictionary *)bookmarks {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kKeyBookmarks];
}


- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:key] == nil) {
		return defaultValue;
	}

	return [defaults boolForKey:key];
}


- (CGFloat)cgFloatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:key] == nil) {
		return defaultValue;
	}

	if (sizeof(CGFloat) == sizeof(float)) {
		return [defaults floatForKey:key];
	}

	return [defaults doubleForKey:key];
}


- (CGFloat)columnGap {
	return [self cgFloatForKey:kKeyColumnGap defaultValue:20];
}


- (CGFloat)fontScale {
	return [self cgFloatForKey:kKeyFontScale defaultValue:1];
}


- (BOOL)isSyntheticSpread {
	return [self boolForKey:kKeyIsSyntheticSpread defaultValue:NO];
}


- (void)setBookmarks:(NSDictionary *)bookmarks {
	if (bookmarks == nil) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyBookmarks];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:kKeyBookmarks];
	}
}


- (void)setCGFloat:(CGFloat)value forKey:(NSString *)key {
	if (sizeof(CGFloat) == sizeof(float)) {
		[[NSUserDefaults standardUserDefaults] setFloat:value forKey:key];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
	}
}


- (void)setColumnGap:(CGFloat)value {
	[self setCGFloat:value forKey:kKeyColumnGap];
}


- (void)setFontScale:(CGFloat)value {
	[self setCGFloat:value forKey:kKeyFontScale];
}


- (void)setIsSyntheticSpread:(BOOL)value {
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:kKeyIsSyntheticSpread];
}


+ (Settings *)shared {
	static Settings *shared = nil;

	if (shared == nil) {
		shared = [[Settings alloc] init];
	}

	return shared;
}


@end
