//
//  SpineItemController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/5/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class RDPackage;
@class RDSpineItem;

@interface SpineItemController : BaseViewController <UIWebViewDelegate> {
	@private int m_currentPageIndex;
	@private BOOL m_didHandleFirstRequest;
	@private RDPackage *m_package;
	@private int m_pageCount;
	@private RDSpineItem *m_spineItem;
	@private UIWebView *m_webView;
}

- (id)initWithPackage:(RDPackage *)package spineItem:(RDSpineItem *)spineItem;

@end
