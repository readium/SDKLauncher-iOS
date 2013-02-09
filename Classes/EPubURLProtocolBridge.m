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
@synthesize currentResponse = m_currentResponse;


- (NSURLResponse *)responseForURL:(NSURL *)url data:(NSData **)data {
	if (data != nil) {
		*data = nil;
	}

	self.currentData = nil;
	self.currentResponse = nil;

	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSDKLauncherEPubURLProtocolBridgeNeedsResponse
		object:self
		userInfo:@{ @"url" : url }];

	// Someone should respond to the notification by setting our current data and current
	// response properties.

	if (data != nil) {
		*data = self.currentData;
	}

	return self.currentResponse;
}


+ (EPubURLProtocolBridge *)shared {
	static EPubURLProtocolBridge *shared = nil;

	if (shared == nil) {
		shared = [[EPubURLProtocolBridge alloc] init];
	}

	return shared;
}


@end
