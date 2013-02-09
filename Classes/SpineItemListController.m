//
//  SpineItemListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "SpineItemListController.h"
#import "RDPackage.h"
#import "RDSpineItem.h"
#import "SpineItemController.h"


@implementation SpineItemListController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[m_package release];
	[super dealloc];
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"SPINE_ITEMS") navBarHidden:NO]) {
		m_package = [package retain];
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];

	m_table = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]
		autorelease];
	m_table.dataSource = self;
	m_table.delegate = self;
	[self.view addSubview:m_table];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil] autorelease];
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
	SpineItemController *c = [[[SpineItemController alloc] initWithPackage:m_package
		spineItem:spineItem] autorelease];
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
