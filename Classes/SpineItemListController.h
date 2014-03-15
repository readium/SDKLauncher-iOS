//
//  SpineItemListController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class RDContainer;
@class RDPackage;

@interface SpineItemListController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private RDContainer *m_container;
	@private RDPackage *m_package;
	@private __weak UITableView *m_table;
}

- (id)initWithContainer:(RDContainer *)container package:(RDPackage *)package;

@end
