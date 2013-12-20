//
//  EPubSettingsController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "EPubSettingsController.h"
#import "EPubSettings.h"


@interface EPubSettingsController ()

- (void)updateCells;

@end


@implementation EPubSettingsController


- (void)cleanUp {
	m_table = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[m_cells release];
	m_cells = nil;
	[super dealloc];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"EPUB_SETTINGS_TITLE") navBarHidden:NO]) {
		if (!IS_IPAD) {
			self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone
				target:self
				action:@selector(onClickDone)] autorelease];
		}

		// Synthetic spread

		UISwitch *sw = [[[UISwitch alloc] init] autorelease];
		sw.on = [EPubSettings shared].isSyntheticSpread;
		[sw addTarget:self action:@selector(onIsSyntheticSpreadDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellIsSyntheticSpread = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil] autorelease];
		m_cellIsSyntheticSpread.accessoryView = sw;
		m_cellIsSyntheticSpread.textLabel.text = LocStr(@"EPUB_SETTINGS_IS_SYNTHETIC_SPREAD");

		// Font scale

		UIStepper *stepper = [[[UIStepper alloc] init] autorelease];
		stepper.minimumValue = 0.2;
		stepper.maximumValue = 5;
		stepper.stepValue = 0.1;
		stepper.value = [EPubSettings shared].fontScale;
		[stepper addTarget:self action:@selector(onFontScaleDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellFontScale = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil] autorelease];
		m_cellFontScale.accessoryView = stepper;

		// Column gap

		int maxValue = MIN(SCREEN_SIZE.width, SCREEN_SIZE.height) / 3.0;
		int stepValue = 5;

		while (maxValue % stepValue != 0) {
			maxValue--;
		}

		stepper = [[[UIStepper alloc] init] autorelease];
		stepper.minimumValue = 0;
		stepper.maximumValue = maxValue;
		stepper.stepValue = stepValue;
		stepper.value = [EPubSettings shared].columnGap;
		[stepper addTarget:self action:@selector(onColumnGapDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellColumnGap = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil] autorelease];
		m_cellColumnGap.accessoryView = stepper;

		// Finish up

		m_cells = [[NSArray alloc] initWithArray:@[
			m_cellIsSyntheticSpread,
			m_cellFontScale,
			m_cellColumnGap
		]];

		[self updateCells];

		self.contentSizeForViewInPopover = CGSizeMake(320, 44 * m_cells.count);

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(updateCells)
			name:kSDKLauncherEPubSettingsDidChange
			object:nil];
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];

	m_table = [[[UITableView alloc] initWithFrame:CGRectZero
		style:UITableViewStylePlain] autorelease];
	m_table.dataSource = self;
	[self.view addSubview:m_table];
}


- (void)onClickDone {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)onColumnGapDidChange:(UIStepper *)stepper {
	[EPubSettings shared].columnGap = stepper.value;
}


- (void)onFontScaleDidChange:(UIStepper *)stepper {
	[EPubSettings shared].fontScale = stepper.value;
}


- (void)onIsSyntheticSpreadDidChange:(UISwitch *)sw {
	[EPubSettings shared].isSyntheticSpread = sw.on;
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_cells objectAtIndex:indexPath.row];
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_cells.count;
}


- (void)updateCells {
	EPubSettings *settings = [EPubSettings shared];

	m_cellColumnGap.textLabel.text = LocStr(@"EPUB_SETTINGS_COLUMN_GAP",
		(int)round(settings.columnGap));

	m_cellFontScale.textLabel.text = LocStr(@"EPUB_SETTINGS_FONT_SCALE",
		(int)round(100.0 * settings.fontScale));
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


@end
