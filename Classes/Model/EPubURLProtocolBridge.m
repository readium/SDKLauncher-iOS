//
//  EPubURLProtocolBridge.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "EPubURLProtocolBridge.h"


NSString * const kSDKLauncherEPubURLProtocolBridgeNeedsResponse =
	@"SDKLauncherEPubURLProtocolBridgeNeedsResponse";


@implementation EPubURLProtocolBridge


@synthesize currentData = m_currentData;


- (NSData *)dataForURL:(NSURL *)url {
	self.currentData = nil;

	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSDKLauncherEPubURLProtocolBridgeNeedsResponse
		object:self
		userInfo:@{ @"url" : url }];

	// Someone should respond to the notification by setting our current data.

	return self.currentData;
}


+ (EPubURLProtocolBridge *)shared {
	static EPubURLProtocolBridge *shared = nil;

	if (shared == nil) {
		shared = [[EPubURLProtocolBridge alloc] init];
	}

	return shared;
}


@end
