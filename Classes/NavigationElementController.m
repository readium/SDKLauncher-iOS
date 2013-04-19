//
//  NavigationElementController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "NavigationElementController.h"
#import "RDNavigationElement.h"
#import "RDPackage.h"
#import "RDSpineItem.h"
#import "SpineItemController.h"


@implementation NavigationElementController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[m_element release];
	[m_package release];
	[super dealloc];
}


- (id)
	initWithNavigationElement:(RDNavigationElement *)element
	package:(RDPackage *)package
	title:(NSString *)title
{
	if (element == nil || package == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:title navBarHidden:NO]) {
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
		initWithNavigationElement:element package:m_package title:element.title] autorelease];

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
	NSString *baseHref = element.content;

	if (baseHref != nil && baseHref.length > 0) {
		NSRange range = [baseHref rangeOfString:@"#"];
		NSString *elementID = nil;

		if (range.location != NSNotFound) {
			elementID = [baseHref substringFromIndex:NSMaxRange(range)];
			baseHref = [baseHref substringToIndex:range.location];
		}

		for (RDSpineItem *spineItem in m_package.spineItems) {
			if ([spineItem.baseHref isEqualToString:baseHref]) {
				SpineItemController *c = [[[SpineItemController alloc]
					initWithPackage:m_package
					spineItem:spineItem
					elementID:elementID] autorelease];
				[self.navigationController pushViewController:c animated:YES];
				return;
			}
		}
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
