//
//  NavigationElementController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "NavigationElementController.h"
#import "EPubViewController.h"
#import "RDContainer.h"
#import "RDNavigationElement.h"
#import "RDPackage.h"
#import "RDSpineItem.h"


@implementation NavigationElementController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[m_container release];
	[m_element release];
	[m_package release];
	[super dealloc];
}


- (id)
	initWithNavigationElement:(RDNavigationElement *)element
	container:(RDContainer *)container
	package:(RDPackage *)package
	title:(NSString *)title
{
	if (element == nil || container == nil || package == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:title navBarHidden:NO]) {
		m_container = [container retain];
		m_element = [element retain];
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


- (void)
	tableView:(UITableView *)tableView
	accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	RDNavigationElement *element = [m_element.children objectAtIndex:indexPath.row];

	NavigationElementController *c = [[[NavigationElementController alloc]
		initWithNavigationElement:element
		container:m_container
		package:m_package
		title:element.title] autorelease];

	if (c != nil) {
		[self.navigationController pushViewController:c animated:YES];
	}
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil] autorelease];
	RDNavigationElement *element = [m_element.children objectAtIndex:indexPath.row];

	if (element.children.count > 0) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	cell.textLabel.text = element.title;
	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	RDNavigationElement *element = [m_element.children objectAtIndex:indexPath.row];

	EPubViewController *c = [[[EPubViewController alloc]
		initWithContainer:m_container
		package:m_package
		navElement:element] autorelease];

	if (c != nil) {
		[self.navigationController pushViewController:c animated:YES];
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_element.children.count;
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
