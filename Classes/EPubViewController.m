//
//  EPubViewController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 6/5/13.
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "EPubViewController.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"
#import "EPubSettings.h"
#import "EPubSettingsController.h"
#import "RDContainer.h"
#import "RDNavigationElement.h"
#import "RDPackage.h"
#import "RDPackageResourceServer.h"
#import "RDSpineItem.h"


@interface EPubViewController ()

- (void)passSettingsToJavaScript;
- (void)updateNavigationItems;
- (void)updateToolbar;

@end


@implementation EPubViewController


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
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

			Bookmark *bookmark = [[Bookmark alloc]
				initWithCFI:[dict objectForKey:@"contentCFI"]
				containerPath:m_container.path
				idref:[dict objectForKey:@"idref"]
				title:title];

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
	m_moIsPlaying = NO;

	if (m_alertAddBookmark != nil) {
		m_alertAddBookmark.delegate = nil;
		[m_alertAddBookmark dismissWithClickedButtonIndex:999 animated:NO];
		m_alertAddBookmark = nil;
	}

	if (m_popover != nil) {
		[m_popover dismissPopoverAnimated:NO];
		m_popover = nil;
	}
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
		return nil;
	}

	// Clear the root URL since its port may have changed.
	package.rootURL = nil;

	RDSpineItem *spineItem = nil;

	if (package.spineItems.count > 0) {
		spineItem = [package.spineItems objectAtIndex:0];
	}

	if (spineItem == nil) {
		return nil;
	}

	if (self = [super initWithTitle:package.title navBarHidden:NO]) {
		m_container = container;
		m_navElement = navElement;
		m_package = package;
		m_spineItem = spineItem;
		m_resourceServer = [[RDPackageResourceServer alloc] initWithPackage:package];
		[self updateNavigationItems];
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
		return nil;
	}

	// Clear the root URL since its port may have changed.
	package.rootURL = nil;

	if (spineItem == nil && package.spineItems.count > 0) {
		spineItem = [package.spineItems objectAtIndex:0];
	}

	if (spineItem == nil) {
		return nil;
	}

	if (self = [super initWithTitle:package.title navBarHidden:NO]) {
		m_container = container;
		m_initialCFI = cfi;
		m_package = package;
		m_resourceServer = [[RDPackageResourceServer alloc] initWithPackage:package];
		m_spineItem = spineItem;
		[self updateNavigationItems];
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];
	self.view.backgroundColor = [UIColor whiteColor];

	// Notifications

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	[nc addObserver:self selector:@selector(onEPubSettingsDidChange:)
		name:kSDKLauncherEPubSettingsDidChange object:nil];

	// Web view

	UIWebView *webView = [[UIWebView alloc] init];
	m_webView = webView;
	webView.delegate = self;
	webView.hidden = YES;
	webView.scalesPageToFit = YES;
	webView.scrollView.bounces = NO;
	[self.view addSubview:webView];

	NSURL *url = [[NSBundle mainBundle] URLForResource:@"reader.html" withExtension:nil];
	[webView loadRequest:[NSURLRequest requestWithURL:url]];
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


- (void)onClickMONext {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.nextMediaOverlay()"];
}


- (void)onClickMOPause {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.toggleMediaOverlay()"];
}


- (void)onClickMOPlay {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.toggleMediaOverlay()"];
}


- (void)onClickMOPrev {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.previousMediaOverlay()"];
}


- (void)onClickNext {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageNext()"];
}


- (void)onClickPrev {
	[m_webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPagePrev()"];
}


- (void)onClickSettings {
	EPubSettingsController *c = [[EPubSettingsController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:c];

	if (IS_IPAD) {
		if (m_popover == nil) {
			m_popover = [[UIPopoverController alloc] initWithContentViewController:nav];
			m_popover.delegate = self;
			[m_popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
				permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	}
	else {
		[self presentViewController:nav animated:YES completion:nil];
	}
}


- (void)onEPubSettingsDidChange:(NSNotification *)notification {
	[self passSettingsToJavaScript];
}


- (void)passSettingsToJavaScript {
	NSData *data = [NSJSONSerialization dataWithJSONObject:[EPubSettings shared].dictionary
		options:0 error:nil];

	if (data == nil) {
		return;
	}

	NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	if (s == nil || s.length == 0) {
		return;
	}

	[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
		@"ReadiumSDK.reader.updateSettings(%@)", s]];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	m_popover = nil;
}


- (void)updateNavigationItems {
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAction
		target:self
		action:@selector(onClickSettings)];
}


- (void)updateToolbar {
	if (m_webView.hidden) {
		self.toolbarItems = nil;
		return;
	}

	NSMutableArray *items = [NSMutableArray arrayWithCapacity:8];

	UIBarButtonItem *itemFixed = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
		target:nil
		action:nil];

	itemFixed.width = 12;

	static NSString *arrowL = @"\u2190";
	static NSString *arrowR = @"\u2192";

	UIBarButtonItem *itemNext = [[UIBarButtonItem alloc]
		initWithTitle:m_currentPageProgressionIsLTR ? arrowR : arrowL
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(onClickNext)];

	UIBarButtonItem *itemPrev = [[UIBarButtonItem alloc]
		initWithTitle:m_currentPageProgressionIsLTR ? arrowL : arrowR
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(onClickPrev)];

	if (m_currentPageProgressionIsLTR) {
		[items addObject:itemPrev];
		[items addObject:itemFixed];
		[items addObject:itemNext];
	}
	else {
		[items addObject:itemNext];
		[items addObject:itemFixed];
		[items addObject:itemPrev];
	}

	[items addObject:itemFixed];

	UILabel *label = [[UILabel alloc] init];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:16];
	label.textColor = [UIColor blackColor];

	if (m_currentPageCount == 0) {
		label.text = @"";
		itemNext.enabled = NO;
		itemPrev.enabled = NO;
	}
	else {
		label.text = LocStr(@"PAGE_X_OF_Y", m_currentPageIndex + 1, m_currentPageCount);

		itemNext.enabled = !(
			(m_currentSpineItemIndex + 1 == m_package.spineItems.count) &&
			(m_currentPageIndex + m_currentOpenPageCount + 1 > m_currentPageCount)
		);

		itemPrev.enabled = !(m_currentSpineItemIndex == 0 && m_currentPageIndex == 0);
	}

	[label sizeToFit];

	[items addObject:[[UIBarButtonItem alloc] initWithCustomView:label]];

	[items addObject:[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil
		action:nil]
	];

	NSString *response = [m_webView stringByEvaluatingJavaScriptFromString:
		@"ReadiumSDK.reader.isMediaOverlayAvailable()"];

	if (response != nil && [response isEqualToString:@"true"]) {
		[items addObject:[[UIBarButtonItem alloc]
			initWithTitle:@"<"
			style:UIBarButtonItemStylePlain
			target:self
			action:@selector(onClickMOPrev)]
		];

		if (m_moIsPlaying) {
			[items addObject:[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemPause
				target:self
				action:@selector(onClickMOPause)]
			];
		}
		else {
			[items addObject:[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
				target:self
				action:@selector(onClickMOPlay)]
			];
		}

		[items addObject:[[UIBarButtonItem alloc]
			initWithTitle:@">"
			style:UIBarButtonItemStylePlain
			target:self
			action:@selector(onClickMONext)]
		];

		[items addObject:itemFixed];
	}

	[items addObject:[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
		target:self
		action:@selector(onClickAddBookmark)]
	];

	self.toolbarItems = items;
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
	NSString *s = @"epubobjc:";

	if ([url hasPrefix:s]) {
		url = [url substringFromIndex:s.length];
		shouldLoad = NO;

		if ([url isEqualToString:@"readerDidInitialize"]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];

			//
			// Important!  Rather than "localhost", "127.0.0.1" is specified in the following URL to work
			// around an issue introduced in iOS 7.0.  When an iOS 7 device is offline (Wi-Fi off, or
			// airplane mode on), audio and video refuses to be served by UIWebView / QuickTime, even
			// though being offline is irrelevant for an embedded HTTP server like ours.  Daniel suggested
			// trying 127.0.0.1 in case the underlying issue was host name resolution, and it worked!
			//
			//   -- Shane
			//

			if (m_package.rootURL == nil || m_package.rootURL.length == 0) {
				m_package.rootURL = [NSString stringWithFormat:
					@"http://127.0.0.1:%d/", m_resourceServer.port];
			}

			[dict setObject:m_package.dictionary forKey:@"package"];
			[dict setObject:[EPubSettings shared].dictionary forKey:@"settings"];

			NSDictionary *pageDict = nil;

			if (m_spineItem == nil) {
			}
			else if (m_initialCFI != nil && m_initialCFI.length > 0) {
				pageDict = @{
					@"idref" : m_spineItem.idref,
					@"elementCfi" : m_initialCFI
				};
			}
			else if (m_navElement.content != nil && m_navElement.content.length > 0) {
				pageDict = @{
					@"contentRefUrl" : m_navElement.content,
					@"sourceFileHref" : (m_navElement.sourceHref == nil ?
						@"" : m_navElement.sourceHref)
				};
			}
			else {
				pageDict = @{
					@"idref" : m_spineItem.idref
				};
			}

			if (pageDict != nil) {
				[dict setObject:pageDict forKey:@"openPageRequest"];
			}

			NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

			if (data != nil) {
				NSString *arg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				[m_webView stringByEvaluatingJavaScriptFromString:[NSString
					stringWithFormat:@"ReadiumSDK.reader.openBook(%@)", arg]];
			}

			return shouldLoad;
		}

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

				if (m_currentOpenPageCount == 1) {
					NSNumber *number = [pageDict objectForKey:@"spineItemPageCount"];
					m_currentPageCount = number.intValue;

					number = [pageDict objectForKey:@"spineItemPageIndex"];
					m_currentPageIndex = number.intValue;

					number = [pageDict objectForKey:@"spineItemIndex"];
					m_currentSpineItemIndex = number.intValue;
				}
			}

			m_webView.hidden = NO;
			[self updateToolbar];
			return shouldLoad;
		}

		s = @"mediaOverlayStatusDidChange?q=";

		if ([url hasPrefix:s]) {
			s = [url substringFromIndex:s.length];
			s = [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

			NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
			NSError *error;

			NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
				options:0 error:&error];

			NSNumber *number = [dict objectForKey:@"isPlaying"];

			if (number != nil) {
				m_moIsPlaying = number.boolValue;
			}

			[self updateToolbar];
			return shouldLoad;
		}
	}

	return shouldLoad;
}


@end
