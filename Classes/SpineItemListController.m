//
//  SpineItemListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemListController.h"
#import "EPubViewController.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "RDSpineItem.h"


@implementation SpineItemListController


- (id)initWithContainer:(RDContainer *)container package:(RDPackage *)package {
	if (container == nil || package == nil) {
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"SPINE_ITEMS") navBarHidden:NO]) {
		m_container = container;
		m_package = package;
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	RDSpineItem *spineItem = [m_package.spineItems objectAtIndex:indexPath.row];
	cell.textLabel.text = spineItem.idref;
	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	RDSpineItem *spineItem = [m_package.spineItems objectAtIndex:indexPath.row];
	EPubViewController *c = [[EPubViewController alloc]
		initWithContainer:m_container
		package:m_package
		spineItem:spineItem
		cfi:nil];
	[self.navigationController pushViewController:c animated:YES];
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_package.spineItems.count;
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (m_table.indexPathForSelectedRow != nil) {
		[m_table deselectRowAtIndexPath:m_table.indexPathForSelectedRow animated:YES];
	}
}


@end
