//
//  ContainerController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "ContainerController.h"
#import "NavigationElementController.h"
#import "PackageMetadataController.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "SpineItemListController.h"


@implementation ContainerController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[m_container release];
	[m_package release];
	[super dealloc];
}


- (id)initWithPath:(NSString *)path {
	if (self = [super initWithTitle:nil navBarHidden:NO]) {
		m_container = [[RDContainer alloc] initWithPath:path];

		if (m_container == nil || m_container.packages.count == 0) {
			[self release];
			return nil;
		}

		m_package = [[m_container.packages objectAtIndex:0] retain];

		NSArray *components = path.pathComponents;
		self.title = (components == nil || components.count == 0) ? @"" : components.lastObject;
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];

	m_table = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped]
		autorelease];
	m_table.dataSource = self;
	m_table.delegate = self;
	[self.view addSubview:m_table];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil] autorelease];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"METADATA");
		}
		else if (indexPath.row == 1) {
			cell.textLabel.text = LocStr(@"SPINE_ITEMS");
		}
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"LIST_OF_FIGURES");
		}
		else if (indexPath.row == 1) {
			cell.textLabel.text = LocStr(@"LIST_OF_ILLUSTRATIONS");
		}
		else if (indexPath.row == 2) {
			cell.textLabel.text = LocStr(@"LIST_OF_TABLES");
		}
		else if (indexPath.row == 3) {
			cell.textLabel.text = LocStr(@"PAGE_LIST");
		}
		else if (indexPath.row == 4) {
			cell.textLabel.text = LocStr(@"TABLE_OF_CONTENTS");
		}
	}

	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			PackageMetadataController *c = [[[PackageMetadataController alloc]
				initWithPackage:m_package] autorelease];
			[self.navigationController pushViewController:c animated:YES];
		}
		else if (indexPath.row == 1) {
			SpineItemListController *c = [[[SpineItemListController alloc]
				initWithPackage:m_package] autorelease];
			[self.navigationController pushViewController:c animated:YES];
		}
	}
	else if (indexPath.section == 1) {
		NavigationElementController *c = nil;
		NSString *title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;

		if (indexPath.row == 0) {
			c = [[[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfFigures
				package:m_package
				title:title] autorelease];
		}
		else if (indexPath.row == 1) {
			c = [[[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfIllustrations
				package:m_package
				title:title] autorelease];
		}
		else if (indexPath.row == 2) {
			c = [[[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfTables
				package:m_package
				title:title] autorelease];
		}
		else if (indexPath.row == 3) {
			c = [[[NavigationElementController alloc]
				initWithNavigationElement:m_package.pageList
				package:m_package
				title:title] autorelease];
		}
		else if (indexPath.row == 4) {
			c = [[[NavigationElementController alloc]
				initWithNavigationElement:m_package.tableOfContents
				package:m_package
				title:title] autorelease];
		}

		if (c == nil) {
			[m_table deselectRowAtIndexPath:indexPath animated:YES];
		}
		else {
			[self.navigationController pushViewController:c animated:YES];
		}
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return
		section == 0 ? 2 :
		section == 1 ? 5 : 0;
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
