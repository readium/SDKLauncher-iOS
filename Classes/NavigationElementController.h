//
//  NavigationElementController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BaseViewController.h"

@class RDNavigationElement;
@class RDPackage;

@interface NavigationElementController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private RDNavigationElement *m_element;
	@private RDPackage *m_package;
	@private UITableView *m_table;
}

- (id)
	initWithNavigationElement:(RDNavigationElement *)element
	package:(RDPackage *)package
	title:(NSString *)title;

@end
