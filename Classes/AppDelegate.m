//
//  AppDelegate.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "AppDelegate.h"
#import "BundleURLProtocol.h"
#import "ContainerListController.h"
#import "EPubURLProtocol.h"


@implementation AppDelegate


- (BOOL)
	application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[NSURLProtocol registerClass:[BundleURLProtocol class]];
	[NSURLProtocol registerClass:[EPubURLProtocol class]];

	m_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	ContainerListController *c = [[[ContainerListController alloc] init] autorelease];
	m_window.rootViewController = [[[UINavigationController alloc]
		initWithRootViewController:c] autorelease];
	[m_window makeKeyAndVisible];

	return YES;
}


- (void)dealloc {
	[m_window release];
	[super dealloc];
}


@end
