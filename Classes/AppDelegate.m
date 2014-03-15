//
//  AppDelegate.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

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
