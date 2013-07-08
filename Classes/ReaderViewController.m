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
#import "RDContainer.h"
#import "RDSpineItem.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"


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


- (id)
initWithContainer:(RDContainer *)container
package:(RDPackage *)package
bookmark:(Bookmark *)bookmark
{
    self = [super init];
    if (self) {
        m_container = [container retain];
        m_package = [package retain];
        m_bookmark = [bookmark retain];
    }
    return self;

}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *cfi = nil;
    if(m_bookmark) {
        m_spineItem = [self spineItemFromBookmark];
        cfi = m_bookmark.cfi;
    }

    
    
	[self loadEpubAtCfi:cfi];
}


#pragma mark - Load epub controller


- (void) loadEpubAtCfi:(NSString *)cfi {
    m_epubViewController = [[EPubViewController alloc]
                            initWithContainer:m_container
                            package:m_package
                            spineItem:m_spineItem
                            cfi:cfi];
    
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




#pragma mark - Toolbar actions

- (void)onClickNext {
	[m_epubViewController openNextPage];
}


- (void)onClickPrev {
	[m_epubViewController openPrevPage];
}


- (void)onClickAddBookmark {
    UIAlertView *alertAddBookmark = [[UIAlertView alloc]
                                     initWithTitle:LocStr(@"ADD_BOOKMARK_PROMPT_TITLE")
                                     message:nil
                                     delegate:self
                                     cancelButtonTitle:LocStr(@"GENERIC_CANCEL")
                                     otherButtonTitles:LocStr(@"GENERIC_OK"), nil];
    alertAddBookmark.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertAddBookmark textFieldAtIndex:0];
    textField.placeholder = LocStr(@"ADD_BOOKMARK_PROMPT_PLACEHOLDER");
    [alertAddBookmark show];
}



#pragma mark - Bookmark managment


- (RDSpineItem*) spineItemFromBookmark {
    RDSpineItem *spineItem = nil;
    
	for (RDSpineItem *currSpineItem in m_package.spineItems) {
		if ([currSpineItem.idref isEqualToString:m_bookmark.idref]) {
			spineItem = currSpineItem;
			break;
		}
	}
    
	return spineItem;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

	if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];
        
		NSString *title = [textField.text stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
		NSDictionary *bookmarkDict = [m_epubViewController bookmarkDict];
        
        Bookmark *bookmark = [[[Bookmark alloc]
                               initWithCFI:[bookmarkDict objectForKey:@"contentCFI"]
                               containerPath:m_container.path
                               idref:[bookmarkDict objectForKey:@"idref"]
                               title:title] autorelease];
        
        if (bookmark == nil) {
            NSLog(@"The bookmark is nil!");
        }
        else {
            [[BookmarkDatabase shared] addBookmark:bookmark];
        }
	}
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
