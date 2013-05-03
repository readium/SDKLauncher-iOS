//
//  BookmarkListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BookmarkListController.h"
#import "Bookmark.h"
#import "BookmarkDatabase.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "SpineItemController.h"


@interface BookmarkListController()

- (void)updateEditDoneButton;

@end


@implementation BookmarkListController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[m_bookmarks release];
	[m_container release];
	[m_package release];
	[super dealloc];
}


- (id)initWithContainer:(RDContainer *)container package:(RDPackage *)package {
	if (container == nil || package == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"BOOKMARKS") navBarHidden:NO]) {
		m_bookmarks = [[[BookmarkDatabase shared]
			bookmarksForContainerPath:container.path] retain];
		m_container = [container retain];
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
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil] autorelease];
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

		[m_bookmarks release];
		m_bookmarks = [[[BookmarkDatabase shared]
			bookmarksForContainerPath:m_container.path] retain];

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

	SpineItemController *c = [[[SpineItemController alloc]
		initWithContainer:m_container
		package:m_package
		bookmark:bookmark] autorelease];

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
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemDone
			target:self
			action:@selector(onClickDone)] autorelease];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
			target:self
			action:@selector(onClickEdit)] autorelease];
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
		[m_bookmarks release];
		m_bookmarks = [bookmarks retain];
		[m_table reloadData];
	}
}


@end
