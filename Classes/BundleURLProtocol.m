//
//  BundleURLProtocol.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/15/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BundleURLProtocol.h"


@implementation BundleURLProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	NSString *s = request.URL.scheme;
	return s != nil && [s isEqualToString:kSDKLauncherWebViewBundleProtocol];
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
	NSData *data = nil;
	NSURLResponse *response = nil;
	NSString *prefix = [kSDKLauncherWebViewBundleProtocol stringByAppendingString:@"://"];
	NSString *s = self.request.URL.absoluteString;

	if (s != nil && [s hasPrefix:prefix] && s.length > prefix.length) {
		s = [s substringFromIndex:prefix.length];
		s = [[NSBundle mainBundle] pathForResource:s ofType:nil];
		data = [NSData dataWithContentsOfFile:s];

		if (data != nil) {
			response = [[[NSHTTPURLResponse alloc]
				initWithURL:[NSURL fileURLWithPath:s]
				statusCode:200
				HTTPVersion:@"HTTP/1.1"
				headerFields:nil] autorelease];
		}
	}

	if (response == nil || data == nil) {
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
