//
//  SpineItemController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemController.h"
#import "EPubURLProtocolBridge.h"
#import "HTMLUtil.h"
#import "PackageResourceServer.h"
#import "RDPackage.h"
#import "RDPackageResource.h"
#import "RDSpineItem.h"


@interface SpineItemController()

- (NSString *)htmlFromData:(NSData *)data;
- (void)updateToolbar;

@end


@implementation SpineItemController


- (void)cleanUp {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	m_webView = nil;
}


- (void)dealloc {
	[m_package release];
	[m_resourceServer release];
	[m_spineItem release];
	[super dealloc];
}


//
// Converts the given HTML data to a string.  The character set and encoding are assumed to be
// UTF-8, UTF-16BE, or UTF-16LE.
//
- (NSString *)htmlFromData:(NSData *)data {
	if (data == nil || data.length == 0) {
		return nil;
	}

	NSString *html = nil;
	UInt8 *bytes = (UInt8 *)data.bytes;

	if (data.length >= 3) {
		if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF16BigEndianStringEncoding];
		}
		else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF16LittleEndianStringEncoding];
		}
		else if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF8StringEncoding];
		}
		else if (bytes[0] == 0x00) {
			// There's a very high liklihood of this being UTF-16BE, just without the BOM.
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF16BigEndianStringEncoding];
		}
		else if (bytes[1] == 0x00) {
			// There's a very high liklihood of this being UTF-16LE, just without the BOM.
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF16LittleEndianStringEncoding];
		}
		else {
			html = [[NSString alloc] initWithData:data
				encoding:NSUTF8StringEncoding];

			if (html == nil) {
				html = [[NSString alloc] initWithData:data
					encoding:NSUTF16BigEndianStringEncoding];

				if (html == nil) {
					html = [[NSString alloc] initWithData:data
						encoding:NSUTF16LittleEndianStringEncoding];
				}
			}
		}
	}

	return [html autorelease];
}


- (id)initWithPackage:(RDPackage *)package spineItem:(RDSpineItem *)spineItem {
	if (package == nil || spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:spineItem.idref navBarHidden:NO]) {
		m_package = [package retain];
		m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package];
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
		m_package.packageUUID,
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

	NSString *packageUUID = [s substringToIndex:range.location];

	if (![packageUUID isEqualToString:m_package.packageUUID]) {
		return;
	}

	s = [s substringFromIndex:packageUUID.length];

	if (![s hasPrefix:@"/"]) {
		return;
	}

	NSString *relativePath = [s substringFromIndex:1];
	BOOL isHTML = NO;
	NSData *data = [m_package resourceAtRelativePath:relativePath isHTML:&isHTML].data;
	EPubURLProtocolBridge *bridge = notification.object;

	BOOL didHandleFirstRequest = m_didHandleFirstRequest;
	m_didHandleFirstRequest = YES;

	if (isHTML) {
		NSString *html = nil;

		if (didHandleFirstRequest) {
			html = [HTMLUtil
				htmlByReplacingMediaURLsInHTML:[self htmlFromData:data]
				relativePath:relativePath
				packageUUID:m_package.packageUUID];
		}
		else {
			// Inject script only if this is the first request.  The reason is that for any
			// given HTML file, we tuck it into an iframe of reader.html.  Once reader.html's
			// iframe makes a request for the same HTML file, we need to avoid injection
			// recursion.
			html = [HTMLUtil htmlByInjectingScriptIntoHTMLAtURL:url.absoluteString];
		}

		if (html != nil && html.length > 0) {
			data = [html dataUsingEncoding:NSUTF8StringEncoding];
		}
	}

	if (data != nil) {
		bridge.currentData = data;
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
