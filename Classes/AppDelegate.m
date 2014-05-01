//
//  AppDelegate.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
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

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "ContainerListController.h"


@interface AppDelegate()

- (void)configureAppearance;

@end


@implementation AppDelegate


- (BOOL)
	application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self configureAppearance];

	ContainerListController *c = [[ContainerListController alloc] init];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:c];
	[self.window makeKeyAndVisible];

	return YES;
}


- (BOOL)
	application:(UIApplication *)application
	openURL:(NSURL *)url
	sourceApplication:(NSString *)sourceApplication
	annotation:(id)annotation
{
	if (!url.isFileURL) {
		return NO;
	}

	NSString *pathSrc = url.path;

	if (![pathSrc.lowercaseString hasSuffix:@".epub"]) {
		return NO;
	}

	NSString *fileName = pathSrc.lastPathComponent;
	NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
		NSUserDomainMask, YES) objectAtIndex:0];
	NSString *pathDst = [docsPath stringByAppendingPathComponent:fileName];
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([fm fileExistsAtPath:pathDst]) {
		return NO;
	}

	[fm copyItemAtPath:pathSrc toPath:pathDst error:nil];
	return YES;
}


- (void)configureAppearance {
	UIColor *color = [UIColor colorWithRed:39/255.0 green:136/255.0 blue:156/255.0 alpha:1];

	if ([self.window respondsToSelector:@selector(setTintColor:)]) {
		self.window.tintColor = color;
	}
	else {
		[[UINavigationBar appearance] setTintColor:color];
		[[UIToolbar appearance] setTintColor:color];
	}
}


@end
