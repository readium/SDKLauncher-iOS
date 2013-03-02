//
//  EPubURLProtocolBridge.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

extern NSString * const kSDKLauncherEPubURLProtocolBridgeNeedsResponse;

@interface EPubURLProtocolBridge : NSObject {
	@private NSData *m_currentData;
}

@property (nonatomic, retain) NSData *currentData;

- (NSData *)dataForURL:(NSURL *)url;
+ (EPubURLProtocolBridge *)shared;

@end
