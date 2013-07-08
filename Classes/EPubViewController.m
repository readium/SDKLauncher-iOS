//
//  EPubViewController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 6/5/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "EPubViewController.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"
#import "EPubURLProtocolBridge.h"
#import "HTMLUtil.h"
#import "PackageResourceServer.h"
#import "RDContainer.h"
#import "RDNavigationElement.h"
#import "RDPackage.h"
#import "RDPackageResource.h"
#import "RDSpineItem.h"
#import "Constants.h"


@interface EPubViewController()

- (NSString *)htmlFromData:(NSData *)data;
- (void)updateToolbar;

@end


@implementation EPubViewController


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[m_alertAddBookmark autorelease];
	m_alertAddBookmark = nil;

	if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];

		NSString *title = [textField.text stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSString *response = [m_webView stringByEvaluatingJavaScriptFromString:
			@"ReadiumSDK.reader.bookmarkCurrentPage()"];

		if (response != nil && response.length > 0) {
			NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
			NSError *error;

			NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
				options:0 error:&error];

			Bookmark *bookmark = [[[Bookmark alloc]
				initWithCFI:[dict objectForKey:@"contentCFI"]
				containerPath:m_container.path
				idref:[dict objectForKey:@"idref"]
				title:title] autorelease];

			if (bookmark == nil) {
				NSLog(@"The bookmark is nil!");
			}
			else {
				[[BookmarkDatabase shared] addBookmark:bookmark];
			}
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
	[m_navElement release];
	[m_initialCFI release];
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


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
{
	return [self initWithContainer:container package:package spineItem:nil cfi:nil];
}


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	bookmark:(Bookmark *)bookmark
{
	RDSpineItem *spineItem = nil;

	for (RDSpineItem *currSpineItem in package.spineItems) {
		if ([currSpineItem.idref isEqualToString:bookmark.idref]) {
			spineItem = currSpineItem;
			break;
		}
	}

	return [self
		initWithContainer:container
		package:package
		spineItem:spineItem
		cfi:bookmark.cfi];
}


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	navElement:(RDNavigationElement *)navElement
{
	if (container == nil || package == nil) {
		[self release];
		return nil;
	}

	RDSpineItem *spineItem = nil;

	if (package.spineItems.count > 0) {
		spineItem = [package.spineItems objectAtIndex:0];
	}

	if (spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:package.title navBarHidden:NO]) {
		m_container = [container retain];
		m_navElement = [navElement retain];
		m_package = [package retain];
		m_spineItem = [spineItem retain];
		m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package];
	}

	return self;
}


- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	spineItem:(RDSpineItem *)spineItem
	cfi:(NSString *)cfi
{
	if (container == nil || package == nil) {
		[self release];
		return nil;
	}

	if (spineItem == nil && package.spineItems.count > 0) {
		spineItem = [package.spineItems objectAtIndex:0];
	}

	if (spineItem == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:package.title navBarHidden:NO]) {
		m_container = [container retain];
		m_initialCFI = [cfi retain];
		m_package = [package retain];
		m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package];
		m_spineItem = [spineItem retain];
	}

	return self;
}




- (void)addBookmark {
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


- (void)openNextPage {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageNext()"];
}


- (void)openPrevPage {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPagePrev()"];
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
			// Return reader.html, which in turn will load the intended HTML.
			html = [HTMLUtil readerHTML];
		}

		if (html != nil && html.length > 0) {
			data = [html dataUsingEncoding:NSUTF8StringEncoding];
		}
	}

	if (data != nil) {
		bridge.currentData = data;
	}
}


- (void)viewDidLayoutSubviews {
	m_webView.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

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


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

}


- (BOOL)
	webView:(UIWebView *)webView
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	BOOL shouldLoad = YES;
	NSString *url = request.URL.absoluteString;
	NSString *s = @"epubobjc:";

	if ([url hasPrefix:s]) {
		url = [url substringFromIndex:s.length];
		shouldLoad = NO;
		s = @"pageDidChange?q=";

		if ([url hasPrefix:s]) {
			s = [url substringFromIndex:s.length];
			s = [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

			NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
			NSError *error;

			NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
				options:0 error:&error];

			NSString *direction = [dict objectForKey:@"pageProgressionDirection"];

			if ([direction isKindOfClass:[NSString class]]) {
				m_currentPageProgressionIsLTR = ![direction isEqualToString:@"rtl"];
			}
			else {
				m_currentPageProgressionIsLTR = YES;
			}

			m_currentOpenPageCount = 0;

			for (NSDictionary *pageDict in [dict objectForKey:@"openPages"]) {
				m_currentOpenPageCount++;

				NSNumber *number = [pageDict objectForKey:@"spineItemPageCount"];
				m_currentPageCount = number.intValue;

				number = [pageDict objectForKey:@"spineItemPageIndex"];
				m_currentPageIndex = number.intValue;

				number = [pageDict objectForKey:@"spineItemIndex"];
				m_currentSpineItemIndex = number.intValue;

				break;
			}

			m_webView.hidden = NO;
			[self.delegate epubViewController:self didDisplayPage:m_currentPageIndex totalPage:m_currentPageCount inItem:m_spineItem atItemIndex:m_currentSpineItemIndex];
		}
	}

	return shouldLoad;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (m_didFinishLoading) {
		return;
	}

	m_didFinishLoading = YES;

	NSData *data = [NSJSONSerialization dataWithJSONObject:m_package.dictionary
		options:0 error:nil];

	if (data == nil) {
		return;
	}

	NSString *packageString = [[[NSString alloc] initWithData:data
		encoding:NSUTF8StringEncoding] autorelease];

	if (packageString == nil || packageString.length == 0) {
		return;
	}

	if (m_spineItem == nil) {
		[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
			@"ReadiumSDK.reader.openBook(%@)", packageString]];
	}
	else if (m_initialCFI != nil && m_initialCFI.length > 0) {
		NSDictionary *dict = @{
			@"idref" : m_spineItem.idref,
			@"elementCfi" : m_initialCFI
		};

		NSString *arg = [[[NSString alloc]
			initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil]
			encoding:NSUTF8StringEncoding] autorelease];

		[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
			@"ReadiumSDK.reader.openBook(%@, %@)", packageString, arg]];
	}
	else if (m_navElement.content != nil && m_navElement.content.length > 0) {
		NSDictionary *dict = @{
			@"contentRefUrl" : m_navElement.content,
			@"sourceFileHref" : (m_navElement.sourceHref == nil ? @"" : m_navElement.sourceHref)
		};

		NSString *arg = [[[NSString alloc]
			initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil]
			encoding:NSUTF8StringEncoding] autorelease];

		[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
			@"ReadiumSDK.reader.openBook(%@, %@)", packageString, arg]];
	}
	else {
		NSDictionary *dict = @{
			@"idref" : m_spineItem.idref
		};

		NSString *arg = [[[NSString alloc]
			initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil]
			encoding:NSUTF8StringEncoding] autorelease];

		[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
			@"ReadiumSDK.reader.openBook(%@, %@)", packageString, arg]];
	}
}


@end
