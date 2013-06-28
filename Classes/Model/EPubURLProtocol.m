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
	return s != nil && [s isEqualToString:kSDKLauncherWebViewSDKProtocol];
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
	NSHTTPURLResponse *response = [[[NSHTTPURLResponse alloc]
		initWithURL:self.request.URL
		statusCode:200
		HTTPVersion:@"HTTP/1.1"
		headerFields:nil] autorelease];

	[self.client URLProtocol:self didReceiveResponse:response
		cacheStoragePolicy:NSURLCacheStorageAllowed];

	// We get called from various threads.  Dispatch the data retrieval to the main thread to
	// simplify code downstream.  Someday multi-threaded data retrieval might be nice but
	// currently causes problems.

	dispatch_async(dispatch_get_main_queue(), ^{
		NSData *data = [[EPubURLProtocolBridge shared] dataForURL:self.request.URL];

		if (data == nil) {
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain
				code:NSURLErrorResourceUnavailable userInfo:nil];
			[self.client URLProtocol:self didFailWithError:error];
		}
		else {
			[self.client URLProtocol:self didLoadData:data];
			[self.client URLProtocolDidFinishLoading:self];
		}
	});
}


- (void)stopLoading {
}


@end
