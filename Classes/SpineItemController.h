//
//  SpineItemController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class Bookmark;
@class PackageResourceServer;
@class RDContainer;
@class RDPackage;
@class RDSpineItem;

@interface SpineItemController : BaseViewController <
	UIAlertViewDelegate,
	UIWebViewDelegate>
{
	@private UIAlertView *m_alertAddBookmark;
	@private RDContainer *m_container;
	@private int m_currentPageIndex;
	@private BOOL m_didFinishLoading;
	@private BOOL m_didHandleFirstRequest;
	@private NSString *m_initialElementID;
	@private NSString *m_initialCFI;
	@private RDPackage *m_package;
	@private int m_pageCount;
	@private PackageResourceServer *m_resourceServer;
	@private RDSpineItem *m_spineItem;
	@private UIWebView *m_webView;
}

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	bookmark:(Bookmark *)bookmark;

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	spineItem:(RDSpineItem *)spineItem
	elementID:(NSString *)elementID;

@end
