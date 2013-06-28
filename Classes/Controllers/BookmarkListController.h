//
//  BookmarkListController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BaseViewController.h"

@class RDContainer;
@class RDPackage;

@interface BookmarkListController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private NSArray *m_bookmarks;
	@private RDContainer *m_container;
	@private RDPackage *m_package;
	@private UITableView *m_table;
}

- (id)initWithContainer:(RDContainer *)container package:(RDPackage *)package;

@end
