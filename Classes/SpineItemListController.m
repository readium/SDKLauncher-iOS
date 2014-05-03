//
//  SpineItemListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
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
