//
//  ReaderViewController.m
//  SDKLauncher-iOS
//
//  Created by Vincent Daubry on 28/06/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "ReaderViewController.h"
#import "EPubViewController.h"
#import "RDPackage.h"

@implementation ReaderViewController


#pragma mark - ViewController life cycle


- (id)
initWithContainer:(RDContainer *)container
package:(RDPackage *)package
spineItem:(RDSpineItem *)spineItem
{
    self = [super init];
    if (self) {
        m_container = [container retain];
		m_package = [package retain];
		m_spineItem = [spineItem retain];
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	[self loadEpub];
}


#pragma mark - Load epub controller


- (void) loadEpub {
    m_epubViewController = [[EPubViewController alloc] initWithContainer:m_container
                                                                                   package:m_package
                                                                                 spineItem:m_spineItem
                                                                                       cfi:nil];
    m_epubViewController.delegate = self;
    [self addChildViewController:m_epubViewController];
    m_epubViewController.view.frame = self.view.bounds;
    [self.view addSubview:m_epubViewController.view];
    [m_epubViewController didMoveToParentViewController:self];
    [m_epubViewController release];
}


#pragma mark - Reader Interface


- (void)updateToolbarWithPageCount:(int)pageCount currentPageIndex:(int)pageIndex inItemIndex:(int)itemIndex {
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
	UIBarButtonItem *itemFixed = [[[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                   target:nil
                                   action:nil] autorelease];
	itemFixed.width = 12;
    
	UIBarButtonItem *itemFlex = [[[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil
                                  action:nil] autorelease];
    
	static NSString *arrowL = @"\u2190";
	static NSString *arrowR = @"\u2192";
    
	UIBarButtonItem *itemNext = [[[UIBarButtonItem alloc]
                                  initWithTitle:arrowR
                                  style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(onClickNext)] autorelease];
    
	UIBarButtonItem *itemPrev = [[[UIBarButtonItem alloc]
                                  initWithTitle:arrowL
                                  style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(onClickPrev)] autorelease];
    
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
    
	if (pageCount == 0) {
		label.text = @"";
		itemNext.enabled = NO;
		itemPrev.enabled = NO;
	}
	else {
		label.text =  [NSString stringWithFormat:@"PAGE %d OF %d", pageIndex + 1, pageCount];
        
        itemNext.enabled = (pageIndex < pageCount && itemIndex < m_package.spineItems.count);
        
		itemPrev.enabled = !(m_spineItem == 0 && pageIndex == 0);
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


- (void)onClickNext {
	[m_epubViewController openNextPage];
}


- (void)onClickPrev {
	[m_epubViewController openPrevPage];
}


- (void)onClickAddBookmark {
    [m_epubViewController addBookmark];
}



#pragma mark - EpubViewControllerDelegate

- (void) epubViewController:(EPubViewController*)spineItemController didReachEndOfSpineItem:(RDSpineItem *)spineItem {
    
}

- (void) epubViewController:(EPubViewController*)spineItemController didReachBeginingOfSpineItem:(RDSpineItem *)spineItem {
    
}

- (void) epubViewController:(EPubViewController*)spineItemController didDisplayPage:(int)pageIndex totalPage:(int)pageCount inItem:(RDSpineItem *)spineItem atItemIndex:(int)spineItemIndex{
    [self updateToolbarWithPageCount:pageCount currentPageIndex:pageIndex inItemIndex:spineItemIndex];
}



@end
