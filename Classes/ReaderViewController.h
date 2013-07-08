//
//  ReaderViewController.h
//  SDKLauncher-iOS
//
//  Created by Vincent Daubry on 28/06/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPubViewController.h"

@class RDContainer;
@class RDNavigationElement;
@class RDPackage;
@class RDSpineItem;
@class Bookmark;


@interface ReaderViewController : UIViewController <EPubViewControllerDelegate> {
    @private RDContainer *m_container;
    @private RDNavigationElement *m_navElement;
    @private RDPackage *m_package;
    @private RDSpineItem *m_spineItem;
    @private EPubViewController *m_epubViewController;
    @private Bookmark *m_bookmark;
}

- (id)
initWithContainer:(RDContainer *)container
package:(RDPackage *)package
spineItem:(RDSpineItem *)spineItem;

- (id)
initWithContainer:(RDContainer *)container
package:(RDPackage *)package
bookmark:(Bookmark *)bookmark;

@end
