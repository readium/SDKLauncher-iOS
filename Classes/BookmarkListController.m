//
//  BookmarkListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
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

#import "BookmarkListController.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"
#import "EPubViewController.h"
#import "RDContainer.h"
#import "RDPackage.h"


@interface BookmarkListController()

- (void)updateEditDoneButton;

@end


@implementation BookmarkListController


- (id)initWithContainer:(RDContainer *)container package:(RDPackage *)package {
	if (container == nil || package == nil) {
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"BOOKMARKS") navBarHidden:NO]) {
		m_bookmarks = [[BookmarkDatabase shared] bookmarksForContainerPath:container.path];
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

	[self updateEditDoneButton];
}


- (void)onClickDone {
	[m_table setEditing:NO animated:YES];
	[self updateEditDoneButton];
}


- (void)onClickEdit {
	[m_table setEditing:YES animated:YES];
	[self updateEditDoneButton];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	Bookmark *bookmark = [m_bookmarks objectAtIndex:indexPath.row];
	cell.textLabel.text = bookmark.title;
	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Bookmark *bookmark = [m_bookmarks objectAtIndex:indexPath.row];
		[[BookmarkDatabase shared] deleteBookmark:bookmark];

		m_bookmarks = [[BookmarkDatabase shared] bookmarksForContainerPath:m_container.path];

		[tableView deleteRowsAtIndexPaths:@[ indexPath ]
			withRowAnimation:UITableViewRowAnimationAutomatic];

		// Rather than update the edit/done button immediately, wait one run loop cycle.  If
		// a swipe gesture triggered this delete and we updated the edit/done button
		// immediately, we would be found to still be in edit mode, which wouldn't be right.

		[self performSelector:@selector(updateEditDoneButton) withObject:nil afterDelay:0];
	}
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Bookmark *bookmark = [m_bookmarks objectAtIndex:indexPath.row];

	EPubViewController *c = [[EPubViewController alloc]
		initWithContainer:m_container
		package:m_package
		bookmark:bookmark];

	if (c != nil) {
		[self.navigationController pushViewController:c animated:YES];
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_bookmarks.count;
}


- (void)updateEditDoneButton {
	if (m_bookmarks.count == 0 || m_table == nil) {
		self.navigationItem.rightBarButtonItem = nil;
	}
	else if (m_table.isEditing) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemDone
			target:self
			action:@selector(onClickDone)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
			target:self
			action:@selector(onClickEdit)];
	}
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	NSArray *bookmarks = [[BookmarkDatabase shared] bookmarksForContainerPath:m_container.path];

	if (bookmarks.count == m_bookmarks.count) {
		if (m_table.indexPathForSelectedRow != nil) {
			[m_table deselectRowAtIndexPath:m_table.indexPathForSelectedRow animated:YES];
		}
	}
	else {
		m_bookmarks = bookmarks;
		[m_table reloadData];
	}
}


@end
