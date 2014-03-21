//
//  NavigationElementController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "NavigationElementController.h"
#import "EPubViewController.h"
#import "NavigationElementItem.h"
#import "RDContainer.h"
#import "RDNavigationElement.h"
#import "RDPackage.h"
#import "RDSpineItem.h"


@interface NavigationElementController () {
	@private NSMutableArray *m_items;
}

- (void)addItem:(NavigationElementItem *)item;

@end


@implementation NavigationElementController


- (void)addItem:(NavigationElementItem *)item {
	if (item.level >= 16) {
		NSLog(@"There are too many levels!");
		return;
	}

	[m_items addObject:item];

	for (RDNavigationElement *e in item.element.children) {
		[self addItem:[[NavigationElementItem alloc]
			initWithNavigationElement:e level:item.level + 1]];
	}
}


- (id)
	initWithNavigationElement:(RDNavigationElement *)element
	container:(RDContainer *)container
	package:(RDPackage *)package
	title:(NSString *)title
{
	if (element == nil || container == nil || package == nil) {
		return nil;
	}

	if (self = [super initWithTitle:title navBarHidden:NO]) {
		m_container = container;
		m_element = element;
		m_items = [[NSMutableArray alloc] init];
		m_package = package;

		for (RDNavigationElement *e in element.children) {
			[self addItem:[[NavigationElementItem alloc] initWithNavigationElement:e level:0]];
		}
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

	NavigationElementItem *item = [m_items objectAtIndex:indexPath.row];

	cell.indentationLevel = item.level;

	cell.textLabel.text = [item.element.title stringByTrimmingCharactersInSet:[NSCharacterSet
		whitespaceAndNewlineCharacterSet]];

	if (item.element.content == nil || item.element.content.length == 0) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.5];
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NavigationElementItem *item = [m_items objectAtIndex:indexPath.row];

	if (item.element.content != nil && item.element.content.length > 0) {
		EPubViewController *c = [[EPubViewController alloc]
			initWithContainer:m_container
			package:m_package
			navElement:item.element];

		if (c != nil) {
			[self.navigationController pushViewController:c animated:YES];
		}
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_items.count;
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
