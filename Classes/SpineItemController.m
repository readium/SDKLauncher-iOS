//
//  SpineItemController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemController.h"
#import "EPubURLProtocol.h"
#import "EPubURLProtocolBridge.h"
#import "RDPackage.h"
#import "RDSpineItem.h"


@implementation SpineItemController


- (void)cleanUp {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	m_webView = nil;
}


- (void)dealloc {
	[m_package release];
	[m_spineItem release];
	[super dealloc];
}


+ (void)initialize {
	[NSURLProtocol registerClass:[EPubURLProtocol class]];
}


- (id)initWithPackage:(RDPackage *)package spineItem:(RDSpineItem *)spineItem {
	if (package == nil || spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:spineItem.idref navBarHidden:NO]) {
		m_package = [package retain];
		m_spineItem = [spineItem retain];
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(onProtocolBridgeNeedsResponse:)
		name:kSDKLauncherEPubURLProtocolBridgeNeedsResponse
		object:nil];

	m_webView = [[[UIWebView alloc] init] autorelease];
	[self.view addSubview:m_webView];

	NSString *url = [NSString stringWithFormat:@"%@://%@/%@",
		kSDKLauncherWebViewProtocol,
		m_package.packageID,
		m_spineItem.baseHref];

	[m_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


- (void)onProtocolBridgeNeedsResponse:(NSNotification *)notification {
	NSURL *url = [notification.userInfo objectForKey:@"url"];
	NSString *s = url.absoluteString;
	NSString *prefix = [kSDKLauncherWebViewProtocol stringByAppendingString:@"://"];

	if (s == nil || ![s hasPrefix:prefix] || s.length == prefix.length) {
		return;
	}

	s = [s substringFromIndex:prefix.length];
	NSRange range = [s rangeOfString:@"/"];

	if (range.location == NSNotFound) {
		return;
	}

	NSString *packageID = [s substringToIndex:range.location];

	if (![packageID isEqualToString:m_package.packageID]) {
		return;
	}

	s = [s substringFromIndex:packageID.length];

	if (![s hasPrefix:@"/"]) {
		return;
	}

	NSString *relativePath = [s substringFromIndex:1];
	NSString *html = nil;
	NSData *data = [m_package dataAtRelativePath:relativePath html:&html];
	EPubURLProtocolBridge *bridge = notification.object;

	if (html != nil) {
		// To do: inject script...
		bridge.currentData = [html dataUsingEncoding:NSUTF8StringEncoding];
		bridge.currentResponse = [[[NSHTTPURLResponse alloc]
			initWithURL:url
			statusCode:200
			HTTPVersion:@"HTTP/1.1"
			headerFields:nil] autorelease];
	}
	else if (data != nil) {
		bridge.currentData = data;
		bridge.currentResponse = [[[NSHTTPURLResponse alloc]
			initWithURL:url
			statusCode:200
			HTTPVersion:@"HTTP/1.1"
			headerFields:nil] autorelease];
	}
}


- (void)viewDidLayoutSubviews {
	m_webView.frame = self.view.bounds;
}


@end
