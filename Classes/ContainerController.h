//
//  ContainerController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class RDContainer;
@class RDPackage;

@interface ContainerController : BaseViewController <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private RDContainer *m_container;
	@private RDPackage *m_package;
	@private __weak UITableView *m_table;
}

- (id)initWithPath:(NSString *)path;

@end
