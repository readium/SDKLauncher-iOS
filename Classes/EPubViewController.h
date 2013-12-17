//
//  EPubViewController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 6/5/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BaseViewController.h"

@class Bookmark;
@class PackageResourceServer;
@class RDContainer;
@class RDNavigationElement;
@class RDPackage;
@class RDSpineItem;

@interface EPubViewController : BaseViewController <
	UIAlertViewDelegate,
	UIPopoverControllerDelegate,
	UIWebViewDelegate>
{
	@private UIAlertView *m_alertAddBookmark;
	@private RDContainer *m_container;
	@private int m_currentOpenPageCount;
	@private int m_currentPageCount;
	@private int m_currentPageIndex;
	@private BOOL m_currentPageProgressionIsLTR;
	@private int m_currentSpineItemIndex;
	@private NSString *m_initialCFI;
	@private BOOL m_moIsPlaying;
	@private RDNavigationElement *m_navElement;
	@private RDPackage *m_package;
	@private UIPopoverController *m_popover;
	@private PackageResourceServer *m_resourceServer;
	@private RDSpineItem *m_spineItem;
	@private UIWebView *m_webView;
}

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package;

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	bookmark:(Bookmark *)bookmark;

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	navElement:(RDNavigationElement *)navElement;

- (id)
	initWithContainer:(RDContainer *)container
	package:(RDPackage *)package
	spineItem:(RDSpineItem *)spineItem
	cfi:(NSString *)cfi;

@end
