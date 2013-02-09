//
//  EPubURLProtocol.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "EPubURLProtocol.h"
#import "EPubURLProtocolBridge.h"


@implementation EPubURLProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	NSString *s = request.URL.scheme;
	return s != nil && [s isEqualToString:kSDKLauncherWebViewProtocol];
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
	NSURLRequest *request = self.request;
	NSData *data = nil;
	NSURLResponse *response = [[EPubURLProtocolBridge shared]
		responseForURL:request.URL data:&data];

	if (response == nil || data == nil) {
		NSError *error = [NSError errorWithDomain:NSURLErrorDomain
			code:NSURLErrorResourceUnavailable userInfo:nil];
		[self.client URLProtocol:self didFailWithError:error];
	}
	else {
		[self.client URLProtocol:self didReceiveResponse:response
			cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[self.client URLProtocol:self didLoadData:data];
		[self.client URLProtocolDidFinishLoading:self];
	}
}


- (void)stopLoading {
}


@end
