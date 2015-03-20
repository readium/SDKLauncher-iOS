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
#import <WebKit/WebKit.h>


@interface EPubViewController () <
	RDPackageResourceServerDelegate,
	UIAlertViewDelegate,
	UIPopoverControllerDelegate,
	UIWebViewDelegate,
	WKScriptMessageHandler>
{
	@private UIAlertView *m_alertAddBookmark;
	@private RDContainer *m_container;
	@private BOOL m_currentPageCanGoLeft;
	@private BOOL m_currentPageCanGoRight;
	@private BOOL m_currentPageIsFixedLayout;
	@private NSArray* m_currentPageOpenPagesArray;
	@private BOOL m_currentPageProgressionIsLTR;
	@private int m_currentPageSpineItemCount;
	@private NSString *m_initialCFI;
	@private BOOL m_moIsPlaying;
	@private RDNavigationElement *m_navElement;
	@private RDPackage *m_package;
	@private UIPopoverController *m_popover;
	@private RDPackageResourceServer *m_resourceServer;
	@private RDSpineItem *m_spineItem;
	@private __weak UIWebView *m_webViewUI;
	@private __weak WKWebView *m_webViewWK;
}

@end


@implementation EPubViewController


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	m_alertAddBookmark = nil;

	if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];

		NSString *title = [textField.text stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		[self executeJavaScript:@"ReadiumSDK.reader.bookmarkCurrentPage()"
			completionHandler:^(id response, NSError *error)
		{
			NSString *s = response;

			if (error != nil || s == nil || ![s isKindOfClass:[NSString class]] || s.length == 0) {
				return;
			}

			NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];

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
		}];
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


- (BOOL)commonInit {

	// Load the special payloads. This is optional (the payloads can be nil), in which case
	// MathJax and annotations.css functionality will be disabled.

	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:@"annotations" ofType:@"css"];
	NSData *payloadAnnotations = (path == nil) ? nil : [[NSData alloc] initWithContentsOfFile:path];
	path = [bundle pathForResource:@"MathJax" ofType:@"js" inDirectory:@"mathjax"];
	NSData *payloadMathJax = (path == nil) ? nil : [[NSData alloc] initWithContentsOfFile:path];

	m_resourceServer = [[RDPackageResourceServer alloc]
		initWithDelegate:self
		package:m_package
		specialPayloadAnnotationsCSS:payloadAnnotations
		specialPayloadMathJaxJS:payloadMathJax];

	if (m_resourceServer == nil) {
		return NO;
	}

	// Configure the package's root URL. Rather than "localhost", "127.0.0.1" is specified in the
	// following URL to work around an issue introduced in iOS 7.0. When an iOS 7 device is offline
	// (Wi-Fi off, or airplane mode on), audio and video fails to be served by UIWebView / QuickTime,
	// even though being offline is irrelevant for an embedded HTTP server. Daniel suggested trying
	// 127.0.0.1 in case the underlying issue was host name resolution, and it works.

	m_package.rootURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/", m_resourceServer.port];

	[self updateNavigationItems];
	return YES;
}


- (void)
	executeJavaScript:(NSString *)javaScript
	completionHandler:(void (^)(id response, NSError *error))completionHandler
{
	if (m_webViewUI != nil) {
		NSString *response = [m_webViewUI stringByEvaluatingJavaScriptFromString:javaScript];
		if (completionHandler != nil) {
			completionHandler(response, nil);
		}
	}
	else if (m_webViewWK != nil) {
		[m_webViewWK evaluateJavaScript:javaScript completionHandler:^(id response, NSError *error) {
			if (error != nil) {
				NSLog(@"%@", error);
			}
			if (completionHandler != nil) {
				if ([NSThread isMainThread]) {
					completionHandler(response, error);
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						completionHandler(response, error);
					});
				}
			}
		}];
	}
	else if (completionHandler != nil) {
		completionHandler(nil, nil);
	}
}


- (void)handleMediaOverlayStatusDidChange:(NSString *)payload {
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

	if (error != nil || dict == nil || ![dict isKindOfClass:[NSDictionary class]]) {
		NSLog(@"The mediaOverlayStatusDidChange payload is invalid! (%@, %@)", error, dict);
	}
	else {
		NSNumber *n = dict[@"isPlaying"];

		if (n != nil && [n isKindOfClass:[NSNumber class]]) {
			m_moIsPlaying = n.boolValue;
			[self updateToolbar];
		}
	}
}


- (void)handlePageDidChange:(NSString *)payload {
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

	if (error != nil || dict == nil || ![dict isKindOfClass:[NSDictionary class]]) {
		NSLog(@"The pageDidChange payload is invalid! (%@, %@)", error, dict);
	}
	else {
		NSNumber *n = dict[@"canGoLeft_"];
		m_currentPageCanGoLeft = [n isKindOfClass:[NSNumber class]] && n.boolValue;

		n = dict[@"canGoRight_"];
		m_currentPageCanGoRight = [n isKindOfClass:[NSNumber class]] && n.boolValue;

		n = dict[@"isRightToLeft"];
		m_currentPageProgressionIsLTR = [n isKindOfClass:[NSNumber class]] && !n.boolValue;

		n = dict[@"isFixedLayout"];
		m_currentPageIsFixedLayout = [n isKindOfClass:[NSNumber class]] && n.boolValue;

		n = dict[@"spineItemCount"];
		m_currentPageSpineItemCount = [n isKindOfClass:[NSNumber class]] ? n.intValue : 0;

		NSArray *array = dict[@"openPages"];
		m_currentPageOpenPagesArray = [array isKindOfClass:[NSArray class]] ? array : nil;

		if (m_webViewUI != nil) {
			m_webViewUI.hidden = NO;
		}
		else if (m_webViewWK != nil) {
			m_webViewWK.hidden = NO;
		}

		[self updateToolbar];
	}
}


- (void)handleReaderDidInitialize {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	dict[@"package"] = m_package.dictionary;
	dict[@"settings"] = [EPubSettings shared].dictionary;

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
		dict[@"openPageRequest"] = pageDict;
	}

	NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

	if (data != nil) {
		NSString *arg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		arg = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)", arg];
		[self executeJavaScript:arg completionHandler:nil];
	}
}


- (instancetype)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
{
	return [self initWithContainer:container package:package spineItem:nil cfi:nil];
}


- (instancetype)
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


- (instancetype)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	navElement:(RDNavigationElement *)navElement
{
	if (container == nil || package == nil) {
		return nil;
	}

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

		if (![self commonInit]) {
			return nil;
		}
	}

	return self;
}


- (instancetype)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	spineItem:(RDSpineItem *)spineItem
	cfi:(NSString *)cfi
{
	if (container == nil || package == nil) {
		return nil;
	}

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
		m_spineItem = spineItem;

		if (![self commonInit]) {
			return nil;
		}
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

	// Create the web view. The choice of web view type is based on the existence of the WKWebView
	// class, but this could be decided some other way.

	NSString *readerHTML = @"reader.html";

	if ([WKWebView class] != nil) {
		WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
		config.allowsInlineMediaPlayback = YES;
		config.mediaPlaybackRequiresUserAction = NO;

		// Configure a "readium" message handler, which is used by host_app_feedback.js.

		WKUserContentController *contentController = [[WKUserContentController alloc] init];
		[contentController addScriptMessageHandler:self name:@"readium"];
		config.userContentController = contentController;

		WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
		m_webViewWK = webView;
		webView.hidden = YES;
		webView.scrollView.bounces = NO;
		[self.view addSubview:webView];

		// RDPackageResourceConnection looks at corePaths and corePrefixes in the following
		// query string to determine what core resources it should provide responses for. Since
		// WKWebView can't handle file URLs, the web server must provide these resources.

		NSString *url = [NSString stringWithFormat:
			@"%@%@?"
			@"corePaths=epubReadingSystem.js,host_app_feedback.js&"
			@"corePrefixes=readium-shared-js",
			m_package.rootURL,
			readerHTML];

		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
	}
	else {
		UIWebView *webView = [[UIWebView alloc] init];
		m_webViewUI = webView;
		webView.allowsInlineMediaPlayback = YES;
		webView.delegate = self;
		webView.hidden = YES;
		webView.mediaPlaybackRequiresUserAction = NO;
		webView.scalesPageToFit = YES;
		webView.scrollView.bounces = NO;
		[self.view addSubview:webView];

		NSURL *url = [[NSBundle mainBundle] URLForResource:readerHTML withExtension:nil];
		[webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
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
	[self executeJavaScript:@"ReadiumSDK.reader.nextMediaOverlay()" completionHandler:nil];
}


- (void)onClickMOPause {
	[self executeJavaScript:@"ReadiumSDK.reader.toggleMediaOverlay()" completionHandler:nil];
}


- (void)onClickMOPlay {
	[self executeJavaScript:@"ReadiumSDK.reader.toggleMediaOverlay()" completionHandler:nil];
}


- (void)onClickMOPrev {
	[self executeJavaScript:@"ReadiumSDK.reader.previousMediaOverlay()" completionHandler:nil];
}


- (void)onClickNext {
	[self executeJavaScript:@"ReadiumSDK.reader.openPageNext()" completionHandler:nil];
}


- (void)onClickPrev {
	[self executeJavaScript:@"ReadiumSDK.reader.openPagePrev()" completionHandler:nil];
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


- (void)
	packageResourceServer:(RDPackageResourceServer *)packageResourceServer
	executeJavaScript:(NSString *)javaScript
{
	if ([NSThread isMainThread]) {
		[self executeJavaScript:javaScript completionHandler:nil];
	}
	else {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self executeJavaScript:javaScript completionHandler:nil];
		});
	}
}


- (void)passSettingsToJavaScript {
	NSData *data = [NSJSONSerialization dataWithJSONObject:[EPubSettings shared].dictionary
		options:0 error:nil];

	if (data != nil) {
		NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		if (s != nil && s.length > 0) {
			s = [NSString stringWithFormat:@"ReadiumSDK.reader.updateSettings(%@)", s];
			[self executeJavaScript:s completionHandler:nil];
		}
	}
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
	if ((m_webViewUI != nil && m_webViewUI.hidden) || (m_webViewWK != nil && m_webViewWK.hidden)) {
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

    BOOL canGoNext = m_currentPageProgressionIsLTR ? m_currentPageCanGoRight : m_currentPageCanGoLeft;
    BOOL canGoPrevious = m_currentPageProgressionIsLTR ? m_currentPageCanGoLeft : m_currentPageCanGoRight;

    itemNext.enabled = canGoNext;
    itemPrev.enabled = canGoPrevious;

	if (m_currentPageOpenPagesArray == nil || [m_currentPageOpenPagesArray count] <= 0) {
		label.text = @"";
	}
	else {

        NSMutableArray *pageNumbers = [NSMutableArray array];

        for (NSDictionary *pageDict in m_currentPageOpenPagesArray) {

            NSNumber *spineItemIndex = [pageDict valueForKey:@"spineItemIndex"];
            NSNumber *spineItemPageIndex = [pageDict valueForKey:@"spineItemPageIndex"];

            int pageIndex = m_currentPageIsFixedLayout ? spineItemIndex.intValue : spineItemPageIndex.intValue;

            [pageNumbers addObject: [NSNumber numberWithInt:pageIndex + 1]];
        }

        NSString* currentPages = [NSString stringWithFormat:@"%@", [pageNumbers componentsJoinedByString:@"-"]];

        int pageCount = 0;
        if ([m_currentPageOpenPagesArray count] > 0)
        {
            NSDictionary *firstOpenPageDict = [m_currentPageOpenPagesArray objectAtIndex:0];
            NSNumber *number = [firstOpenPageDict valueForKey:@"spineItemPageCount"];

            pageCount = m_currentPageIsFixedLayout ? m_currentPageSpineItemCount: number.intValue;
        }
        NSString* totalPages = [NSString stringWithFormat:@"%d", pageCount];

        label.text = LocStr(@"PAGE_X_OF_Y", [currentPages UTF8String], [totalPages UTF8String], m_currentPageIsFixedLayout?[@"FXL" UTF8String]:[@"reflow" UTF8String]);
	}

	[label sizeToFit];

	[items addObject:[[UIBarButtonItem alloc] initWithCustomView:label]];

	[items addObject:[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil
		action:nil]
	];

	[self executeJavaScript:@"ReadiumSDK.reader.isMediaOverlayAvailable()"
		completionHandler:^(id response, NSError *error)
	{
		if (error == nil && response != nil && (
			([response isKindOfClass:[NSNumber class]] && ((NSNumber *)response).boolValue)
				||
			([response isKindOfClass:[NSString class]] && [((NSString *)response) isEqualToString:@"true"])
		))
		{
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
	}];
}


- (void)
	userContentController:(WKUserContentController *)userContentController
	didReceiveScriptMessage:(WKScriptMessage *)message
{
	if (![NSThread isMainThread]) {
		NSLog(@"A script message unexpectedly arrived on a non-main thread!");
	}

	NSArray *body = message.body;

	if (message.name == nil ||
		![message.name isEqualToString:@"readium"] ||
		body == nil ||
		![body isKindOfClass:[NSArray class]] ||
		body.count == 0 ||
		![body[0] isKindOfClass:[NSString class]])
	{
		NSLog(@"Invalid script message! (%@, %@)", message.name, message.body);
		return;
	}

	NSString *messageName = body[0];

	if ([messageName isEqualToString:@"mediaOverlayStatusDidChange"]) {
		if (body.count < 2 || ![body[1] isKindOfClass:[NSString class]]) {
			NSLog(@"The mediaOverlayStatusDidChange payload is invalid!");
		}
		else {
			[self handleMediaOverlayStatusDidChange:body[1]];
		}
	}
	else if ([messageName isEqualToString:@"pageDidChange"]) {
		if (body.count < 2 || ![body[1] isKindOfClass:[NSString class]]) {
			NSLog(@"The pageDidChange payload is invalid!");
		}
		else {
			[self handlePageDidChange:body[1]];
		}
	}
	else if ([messageName isEqualToString:@"readerDidInitialize"]) {
		[self handleReaderDidInitialize];
	}
}


- (void)viewDidLayoutSubviews {
	CGSize size = self.view.bounds.size;

	if (m_webViewUI != nil) {
		m_webViewUI.frame = self.view.bounds;
	}
	else if (m_webViewWK != nil) {
		self.automaticallyAdjustsScrollViewInsets = NO;
		CGFloat y0 = self.topLayoutGuide.length;
		CGFloat y1 = size.height - self.bottomLayoutGuide.length;
		m_webViewWK.frame = CGRectMake(0, y0, size.width, y1 - y0);
		m_webViewWK.scrollView.contentInset = UIEdgeInsetsZero;
		m_webViewWK.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
	}
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

		s = @"mediaOverlayStatusDidChange?q=";

		if ([url hasPrefix:s]) {
			s = [url substringFromIndex:s.length];
			s = [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[self handleMediaOverlayStatusDidChange:s];
		}
		else {
			s = @"pageDidChange?q=";

			if ([url hasPrefix:s]) {
				s = [url substringFromIndex:s.length];
				s = [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[self handlePageDidChange:s];
			}
			else if ([url isEqualToString:@"readerDidInitialize"]) {
				[self handleReaderDidInitialize];
			}
		}
	}

	return shouldLoad;
}


@end
