//
//  EPubSettings.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
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
