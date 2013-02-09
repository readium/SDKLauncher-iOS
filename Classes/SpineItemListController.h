//
//  SpineItemListController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class RDPackage;

@interface SpineItemListController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private RDPackage *m_package;
	@private UITableView *m_table;
}

- (id)initWithPackage:(RDPackage *)package;

@end
