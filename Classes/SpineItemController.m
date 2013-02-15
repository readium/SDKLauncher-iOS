//
//  SpineItemController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemController.h"
#import "EPubURLProtocolBridge.h"
#import "RDPackage.h"
#import "RDSpineItem.h"
#import "ScriptInjector.h"


@interface SpineItemController()

- (void)updateToolbar;

@end


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


- (id)initWithPackage:(RDPackage *)package spineItem:(RDSpineItem *)spineItem {
	if (package == nil || spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:spineItem.idref navBarHidden:NO]) {
		m_package = [package retain];
		m_spineItem = [spineItem retain];
		[self updateToolbar];
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
	m_webView.delegate = self;
	[self.view addSubview:m_webView];

	NSString *url = [NSString stringWithFormat:@"%@://%@/%@",
		kSDKLauncherWebViewSDKProtocol,
		m_package.packageID,
		m_spineItem.baseHref];

	[m_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


- (void)onClickNext {
	[m_webView stringByEvaluatingJavaScriptFromString:
		@"window.ReadiumSdk.Reader.getInstance().moveNextPage()"];
}


- (void)onClickPrev {
	[m_webView stringByEvaluatingJavaScriptFromString:
		@"window.ReadiumSdk.Reader.getInstance().movePrevPage()"];
}


- (void)onProtocolBridgeNeedsResponse:(NSNotification *)notification {
	NSURL *url = [notification.userInfo objectForKey:@"url"];
	NSString *s = url.absoluteString;
	NSString *prefix = [kSDKLauncherWebViewSDKProtocol stringByAppendingString:@"://"];

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
	BOOL isHTML = NO;
	NSData *data = [m_package dataAtRelativePath:relativePath isHTML:&isHTML];
	EPubURLProtocolBridge *bridge = notification.object;

	BOOL didHandleFirstRequest = m_didHandleFirstRequest;
	m_didHandleFirstRequest = YES;

	if (isHTML && !didHandleFirstRequest) {

		// Inject script only if this is the first request.  The reason is that for any given
		// HTML file, we tuck it into an iframe of reader.html.  Once reader.html's iframe
		// makes a request for the same HTML file, we need to avoid injection recursion.

		NSString *html = [ScriptInjector htmlByInjectingIntoHTMLAtURL:url.absoluteString];
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


- (void)updateToolbar {
	UIBarButtonItem *itemFixed = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
		target:nil
		action:nil] autorelease];
	itemFixed.width = 16;

	UIBarButtonItem *itemPrev = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
		target:self
		action:@selector(onClickPrev)] autorelease];

	UIBarButtonItem *itemNext = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
		target:self
		action:@selector(onClickNext)] autorelease];

	UILabel *label = [[[UILabel alloc] init] autorelease];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont boldSystemFontOfSize:16];
	label.shadowColor = [UIColor colorWithWhite:0 alpha:IS_IPAD ? 0.0 : 0.5];
	label.shadowOffset = CGSizeMake(0, -1);
	label.textColor = IS_IPAD ? [UIColor blackColor] : [UIColor whiteColor];

	if (m_pageCount == 0) {
		label.text = @"";
	}
	else {
		label.text = LocStr(@"PAGE_X_OF_Y", m_currentPageIndex + 1, m_pageCount);
	}

	[label sizeToFit];

	UIBarButtonItem *itemLabel = [[[UIBarButtonItem alloc]
		initWithCustomView:label] autorelease];

	self.toolbarItems = @[ itemPrev, itemFixed, itemNext, itemFixed, itemLabel ];
}


- (void)viewDidLayoutSubviews {
	m_webView.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (self.navigationController != nil) {
		[self.navigationController setToolbarHidden:NO animated:YES];
	}
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if (self.navigationController != nil) {
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
}


- (BOOL)
	webView:(UIWebView *)webView
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	BOOL shouldLoad = YES;
	NSString *url = request.URL.absoluteString;

	if ([url hasPrefix:@"epubobjc:"]) {
		url = [url substringFromIndex:9];
		shouldLoad = NO;

		if ([url hasPrefix:@"setPageIndexAndPageCount/"]) {
			NSArray *components = [url componentsSeparatedByString:@"/"];

			if (components.count == 3) {
				NSString *pageIndex = [components objectAtIndex:1];
				NSString *pageCount = [components objectAtIndex:2];
				m_currentPageIndex = pageIndex.intValue;
				m_pageCount = pageCount.intValue;
				[self updateToolbar];
			}
		}
	}

	return shouldLoad;
}


@end
