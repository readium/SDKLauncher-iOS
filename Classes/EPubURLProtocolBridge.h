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
	@private NSURLResponse *m_currentResponse;
}

@property (nonatomic, retain) NSData *currentData;
@property (nonatomic, retain) NSURLResponse *currentResponse;

- (NSURLResponse *)responseForURL:(NSURL *)url data:(NSData **)data;
+ (EPubURLProtocolBridge *)shared;

@end
