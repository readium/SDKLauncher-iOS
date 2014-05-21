//
//  Settings.m
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

#import "Settings.h"


#define kKeyBookmarks @"SDKLauncherBookmarks"
#define kKeyColumnGap @"SDKLauncherColumnGap"
#define kKeyFontScale @"SDKLauncherFontScale"
#define kKeyScroll @"SDKLauncherScroll"
#define kKeySyntheticSpread @"SDKLauncherSyntheticSpread"


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


- (EPubSettingsScroll)scroll {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *number = [defaults objectForKey:kKeyScroll];
	return (number == nil || ![number isKindOfClass:[NSNumber class]]) ?
		EPubSettingsScrollAuto : number.integerValue;
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


- (void)setScroll:(EPubSettingsScroll)value {
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kKeyScroll];
}


- (void)setSyntheticSpread:(EPubSettingsSyntheticSpread)value {
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kKeySyntheticSpread];
}


+ (Settings *)shared {
	static Settings *shared = nil;

	if (shared == nil) {
		shared = [[Settings alloc] init];
	}

	return shared;
}


- (EPubSettingsSyntheticSpread)syntheticSpread {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *number = [defaults objectForKey:kKeySyntheticSpread];
	return (number == nil || ![number isKindOfClass:[NSNumber class]]) ?
		EPubSettingsSyntheticSpreadAuto : number.integerValue;
}


@end
