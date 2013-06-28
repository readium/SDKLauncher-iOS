//
//  ContainerListController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@interface ContainerListController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private NSArray *m_paths;
	@private UITableView *m_table;
}

@end
