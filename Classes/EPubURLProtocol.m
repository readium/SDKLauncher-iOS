//
//  EPubURLProtocol.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/10/14.
//  Copyright (c) 2014 The Readium Foundation. All rights reserved.
//

#import "EPubURLProtocol.h"


@implementation EPubURLProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	NSString *s = request.URL.absoluteString;
	return s != nil && [s hasPrefix:kSDKLauncherWebViewSDKURL];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}


- (id)
	initWithRequest:(NSURLRequest *)request
	cachedResponse:(NSCachedURLResponse *)cachedResponse
	client:(id<NSURLProtocolClient>)client
{
	if (self = [super initWithRequest:request cachedResponse:cachedResponse client:client]) {
	}

	return self;
}


- (void)startLoading {
	NSString *s = self.request.URL.absoluteString;

	if (s == nil || ![s hasPrefix:kSDKLauncherWebViewSDKURL]) {
		NSLog(@"The EPUB URL is invalid!");
		return;
	}

	s = [s substringFromIndex:kSDKLauncherWebViewSDKURL.length];
	s = [[NSBundle mainBundle] pathForResource:s ofType:nil];
	NSData *data = [NSData dataWithContentsOfFile:s];
	NSURLResponse *response = nil;

	if (data != nil) {
		response = [[[NSHTTPURLResponse alloc]
			initWithURL:[NSURL fileURLWithPath:s]
			statusCode:200
			HTTPVersion:@"HTTP/1.1"
			headerFields:nil] autorelease];
	}

	if (data == nil || response == nil) {
		NSError *error = [NSError errorWithDomain:NSURLErrorDomain
			code:NSURLErrorResourceUnavailable userInfo:nil];
		[self.client URLProtocol:self didFailWithError:error];
	}
	else {
		[self.client URLProtocol:self didReceiveResponse:response
			cacheStoragePolicy:NSURLCacheStorageAllowed];
		[self.client URLProtocol:self didLoadData:data];
		[self.client URLProtocolDidFinishLoading:self];
	}
}


- (void)stopLoading {
}


@end
