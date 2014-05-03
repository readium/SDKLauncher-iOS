//
//  ContainerController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ContainerController.h"
#import "BookmarkDatabase.h"
#import "BookmarkListController.h"
#import "NavigationElementController.h"
#import "PackageMetadataController.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "SpineItemListController.h"


@implementation ContainerController


- (id)initWithPath:(NSString *)path {
	if (self = [super initWithTitle:nil navBarHidden:NO]) {
		m_container = [[RDContainer alloc] initWithPath:path];
		m_package = m_container.firstPackage;

		if (m_package == nil) {
			return nil;
		}

		NSArray *components = path.pathComponents;
		self.title = (components == nil || components.count == 0) ? @"" : components.lastObject;
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
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
	else if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"BOOKMARKS_WITH_COUNT", [[BookmarkDatabase shared]
				bookmarksForContainerPath:m_container.path].count);
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
			PackageMetadataController *c = [[PackageMetadataController alloc]
				initWithPackage:m_package];
			[self.navigationController pushViewController:c animated:YES];
		}
		else if (indexPath.row == 1) {
			SpineItemListController *c = [[SpineItemListController alloc]
				initWithContainer:m_container package:m_package];
			[self.navigationController pushViewController:c animated:YES];
		}
	}
	else if (indexPath.section == 1) {
		NavigationElementController *c = nil;
		NSString *title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;

		if (indexPath.row == 0) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfFigures
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 1) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfIllustrations
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 2) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfTables
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 3) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.pageList
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 4) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.tableOfContents
				container:m_container
				package:m_package
				title:title];
		}

		if (c == nil) {
			[m_table deselectRowAtIndexPath:indexPath animated:YES];
		}
		else {
			[self.navigationController pushViewController:c animated:YES];
		}
	}
	if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			BookmarkListController *c = [[BookmarkListController alloc]
				initWithContainer:m_container package:m_package];

			if (c != nil) {
				[self.navigationController pushViewController:c animated:YES];
			}
		}
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return
		section == 0 ? 2 :
		section == 1 ? 5 :
		section == 2 ? 1 : 0;
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (m_table.indexPathForSelectedRow != nil) {
		[m_table deselectRowAtIndexPath:m_table.indexPathForSelectedRow animated:YES];
	}

	// Bookmarks may have been added since we were last visible, so update the bookmark
	// count within the cell if needed.

	for (UITableViewCell *cell in m_table.visibleCells) {
		NSIndexPath *indexPath = [m_table indexPathForCell:cell];

		if (indexPath.section == 2 && indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"BOOKMARKS_WITH_COUNT", [[BookmarkDatabase shared]
				bookmarksForContainerPath:m_container.path].count);
		}
	}
}


@end
