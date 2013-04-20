//
//  SpineItemController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemController.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"
#import "EPubURLProtocolBridge.h"
#import "HTMLUtil.h"
#import "PackageResourceServer.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "RDPackageResource.h"
#import "RDSpineItem.h"


@interface SpineItemController()

- (void)goToPageIndex:(int)pageIndex;
- (NSString *)htmlFromData:(NSData *)data;
- (int)pageIndexForCFI:(NSString *)cfi;
- (int)pageIndexForElementID:(NSString *)elementID;
- (void)updateToolbar;

@end


@implementation SpineItemController


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[m_alertAddBookmark autorelease];
	m_alertAddBookmark = nil;

	if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];

		NSString *title = [textField.text stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSString *cfi = [m_webView stringByEvaluatingJavaScriptFromString:
			@"ReadiumSDK.reader.getFirstVisibleElementCfi()"];

		Bookmark *bookmark = [[[Bookmark alloc]
			initWithCFI:cfi
			containerPath:m_container.path
			idref:m_spineItem.idref
			title:title] autorelease];

		if (bookmark == nil) {
			NSLog(@"The bookmark is nil!");
		}
		else {
			[[BookmarkDatabase shared] addBookmark:bookmark];
		}
	}
}


- (void)cleanUp {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	m_webView = nil;

	if (m_alertAddBookmark != nil) {
		m_alertAddBookmark.delegate = nil;
		[m_alertAddBookmark dismissWithClickedButtonIndex:999 animated:NO];
		[m_alertAddBookmark release];
		m_alertAddBookmark = nil;
	}
}


- (void)dealloc {
	[m_container release];
	[m_initialCFI release];
	[m_initialElementID release];
	[m_package release];
	[m_resourceServer release];
	[m_spineItem release];
	[super dealloc];
}


- (void)goToPageIndex:(int)pageIndex {
	NSString *s = [NSString stringWithFormat:@"ReadiumSDK.reader.openPage(%d)", pageIndex];
	[m_webView stringByEvaluatingJavaScriptFromString:s];
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


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	bookmark:(Bookmark *)bookmark
{
	if (container == nil || package == nil || bookmark == nil) {
		[self release];
		return nil;
	}

	RDSpineItem *spineItem = nil;

	for (RDSpineItem *currSpineItem in package.spineItems) {
		if ([currSpineItem.idref isEqualToString:bookmark.idref]) {
			spineItem = currSpineItem;
			break;
		}
	}

	if (spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:spineItem.idref navBarHidden:NO]) {
		m_container = [container retain];
		m_initialCFI = [bookmark.cfi retain];
		m_package = [package retain];
		m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package];
		m_spineItem = [spineItem retain];
	}

	return self;

	return self;
}


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	spineItem:(RDSpineItem *)spineItem
	elementID:(NSString *)elementID
{
	if (container == nil || package == nil || spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:spineItem.idref navBarHidden:NO]) {
		m_container = [container retain];
		m_initialElementID = [elementID retain];
		m_package = [package retain];
		m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package];
		m_spineItem = [spineItem retain];
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
	self.view.backgroundColor = [UIColor whiteColor];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(onProtocolBridgeNeedsResponse:)
		name:kSDKLauncherEPubURLProtocolBridgeNeedsResponse
		object:nil];

	m_webView = [[[UIWebView alloc] init] autorelease];
	m_webView.delegate = self;
	m_webView.hidden = YES;
	m_webView.scrollView.bounces = NO;
	[self.view addSubview:m_webView];

	NSString *url = [NSString stringWithFormat:@"%@://%@/%@",
		kSDKLauncherWebViewSDKProtocol,
		m_package.packageUUID,
		m_spineItem.baseHref];

	[m_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


- (void)onClickAddBookmark {
	if (m_alertAddBookmark == nil) {
		m_alertAddBookmark = [[UIAlertView alloc]
			initWithTitle:LocStr(@"ADD_BOOKMARK_PROMPT_TITLE")
			message:nil
			delegate:self
			cancelButtonTitle:LocStr(@"GENERIC_CANCEL")
			otherButtonTitles:LocStr(@"GENERIC_OK"), nil];
		m_alertAddBookmark.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *textField = [m_alertAddBookmark textFieldAtIndex:0];
		textField.placeholder = LocStr(@"ADD_BOOKMARK_PROMPT_PLACEHOLDER");
		[m_alertAddBookmark show];
	}
}


- (void)onClickNext {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.moveNextPage()"];
}


- (void)onClickPrev {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.movePrevPage()"];
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


- (int)pageIndexForCFI:(NSString *)cfi {
	if (cfi == nil || cfi.length == 0) {
		return 0;
	}

	NSString *request = [NSString stringWithFormat:
		@"ReadiumSDK.reader.getPageForElementCfi(\"%@\")", cfi];
	NSString *response = [m_webView stringByEvaluatingJavaScriptFromString:request];
	return response.intValue;
}


- (int)pageIndexForElementID:(NSString *)elementID {
	if (elementID == nil || elementID.length == 0) {
		return 0;
	}

	NSString *request = [NSString stringWithFormat:
		@"ReadiumSDK.reader.getPageForElementId(\"%@\")", elementID];
	NSString *response = [m_webView stringByEvaluatingJavaScriptFromString:request];
	return response.intValue;
}


- (void)showContent {
	m_webView.hidden = NO;
	[self updateToolbar];
}


- (void)updateToolbar {
	if (m_webView.hidden) {
		self.toolbarItems = nil;
		return;
	}

	UIBarButtonItem *itemFixed = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
		target:nil
		action:nil] autorelease];
	itemFixed.width = 12;

	UIBarButtonItem *itemFlex = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil
		action:nil] autorelease];

	UIBarButtonItem *itemPrev = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
		target:self
		action:@selector(onClickPrev)] autorelease];

	UIBarButtonItem *itemNext = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
		target:self
		action:@selector(onClickNext)] autorelease];

	UIBarButtonItem *itemAddBookmark = [[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
		target:self
		action:@selector(onClickAddBookmark)] autorelease];

	UILabel *label = [[[UILabel alloc] init] autorelease];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont boldSystemFontOfSize:16];
	label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
	label.shadowOffset = CGSizeMake(0, -1);
	label.textColor = [UIColor whiteColor];

	if (m_pageCount == 0) {
		label.text = @"";
	}
	else {
		label.text = LocStr(@"PAGE_X_OF_Y", m_currentPageIndex + 1, m_pageCount);
	}

	[label sizeToFit];

	UIBarButtonItem *itemLabel = [[[UIBarButtonItem alloc]
		initWithCustomView:label] autorelease];

	self.toolbarItems = @[
		itemPrev,
		itemFixed,
		itemNext,
		itemFixed,
		itemLabel,
		itemFlex,
		itemAddBookmark ];
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

				if (!m_didFinishLoading && m_pageCount > 0) {
					m_didFinishLoading = YES;

					if (m_initialCFI != nil && m_initialCFI.length > 0) {
						int index = [self pageIndexForCFI:m_initialCFI];
						[self goToPageIndex:index];
					}
					else if (m_initialElementID != nil && m_initialElementID.length > 0) {
						int index = [self pageIndexForElementID:m_initialElementID];
						[self goToPageIndex:index];
					}
				}

				if (m_pageCount > 0) {
					[self performSelector:@selector(showContent) withObject:nil afterDelay:0.1];
				}
			}
		}
	}

	return shouldLoad;
}


@end
