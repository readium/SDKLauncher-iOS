//
//  EPubSettingsController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
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

#import "EPubSettingsController.h"
#import "EPubSettings.h"


@interface EPubSettingsController () <
	UITableViewDataSource,
	UITableViewDelegate>
{
	@private UITableViewCell *m_cellColumnGap;
	@private UITableViewCell *m_cellFontScale;
	@private UITableViewCell *m_cellScroll;
	@private UITableViewCell *m_cellScrollAuto;
	@private UITableViewCell *m_cellScrollContinuous;
	@private UITableViewCell *m_cellScrollDoc;
	@private UITableViewCell *m_cellSyntheticSpread;
	@private UITableViewCell *m_cellSyntheticSpreadAuto;
	@private UITableViewCell *m_cellSyntheticSpreadDouble;
	@private UITableViewCell *m_cellSyntheticSpreadSingle;
	@private NSArray *m_cells;
	@private __weak UITableView *m_table;
}

- (void)updateCells;

@end


@implementation EPubSettingsController


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"EPUB_SETTINGS_TITLE") navBarHidden:NO]) {
		if (!IS_IPAD) {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone
				target:self
				action:@selector(onTapDone)];
		}

		// Column gap

		int maxValue = MIN(SCREEN_SIZE.width, SCREEN_SIZE.height) / 3.0;
		int stepValue = 5;

		while (maxValue % stepValue != 0) {
			maxValue--;
		}

		UIStepper *stepper = [[UIStepper alloc] init];
		stepper.minimumValue = 0;
		stepper.maximumValue = maxValue;
		stepper.stepValue = stepValue;
		stepper.value = [EPubSettings shared].columnGap;
		[stepper addTarget:self action:@selector(onColumnGapDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellColumnGap = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil];
		m_cellColumnGap.accessoryView = stepper;
		m_cellColumnGap.selectionStyle = UITableViewCellSelectionStyleNone;

		// Font scale

		stepper = [[UIStepper alloc] init];
		stepper.minimumValue = 0.2;
		stepper.maximumValue = 5;
		stepper.stepValue = 0.1;
		stepper.value = [EPubSettings shared].fontScale;
		[stepper addTarget:self action:@selector(onFontScaleDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellFontScale = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil];
		m_cellFontScale.accessoryView = stepper;
		m_cellFontScale.selectionStyle = UITableViewCellSelectionStyleNone;

		// Scroll

		m_cellScroll = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellScroll.selectionStyle = UITableViewCellSelectionStyleNone;
		m_cellScroll.textLabel.text = LocStr(@"EPUB_SETTINGS_SCROLL");

		m_cellScrollAuto = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellScrollAuto.indentationLevel = 1;
		m_cellScrollAuto.textLabel.text = LocStr(@"EPUB_SETTINGS_SCROLL_AUTO");

		m_cellScrollContinuous = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellScrollContinuous.indentationLevel = 1;
		m_cellScrollContinuous.textLabel.text = LocStr(@"EPUB_SETTINGS_SCROLL_CONTINUOUS");

		m_cellScrollDoc = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellScrollDoc.indentationLevel = 1;
		m_cellScrollDoc.textLabel.text = LocStr(@"EPUB_SETTINGS_SCROLL_DOC");

		// Synthetic spread

		m_cellSyntheticSpread = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellSyntheticSpread.selectionStyle = UITableViewCellSelectionStyleNone;
		m_cellSyntheticSpread.textLabel.text = LocStr(@"EPUB_SETTINGS_SYNTHETIC_SPREAD");

		m_cellSyntheticSpreadAuto = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellSyntheticSpreadAuto.indentationLevel = 1;
		m_cellSyntheticSpreadAuto.textLabel.text = LocStr(@"EPUB_SETTINGS_SYNTHETIC_SPREAD_AUTO");

		m_cellSyntheticSpreadDouble = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellSyntheticSpreadDouble.indentationLevel = 1;
		m_cellSyntheticSpreadDouble.textLabel.text = LocStr(@"EPUB_SETTINGS_SYNTHETIC_SPREAD_DOUBLE");

		m_cellSyntheticSpreadSingle = [[UITableViewCell alloc] initWithStyle:
			UITableViewCellStyleDefault reuseIdentifier:nil];
		m_cellSyntheticSpreadSingle.indentationLevel = 1;
		m_cellSyntheticSpreadSingle.textLabel.text = LocStr(@"EPUB_SETTINGS_SYNTHETIC_SPREAD_SINGLE");

		// Finish up

		m_cells = @[
			m_cellScroll,
			m_cellScrollAuto,
			m_cellScrollDoc,
			m_cellScrollContinuous,
			m_cellSyntheticSpread,
			m_cellSyntheticSpreadAuto,
			m_cellSyntheticSpreadSingle,
			m_cellSyntheticSpreadDouble,
			m_cellFontScale,
			m_cellColumnGap
		];

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
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (void)onColumnGapDidChange:(UIStepper *)stepper {
	[EPubSettings shared].columnGap = stepper.value;
}


- (void)onFontScaleDidChange:(UIStepper *)stepper {
	[EPubSettings shared].fontScale = stepper.value;
}


- (void)onTapDone {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_cells objectAtIndex:indexPath.row];
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

	if (cell == m_cellScrollAuto) {
		[EPubSettings shared].scroll = EPubSettingsScrollAuto;
	}
	else if (cell == m_cellScrollContinuous) {
		[EPubSettings shared].scroll = EPubSettingsScrollContinuous;
	}
	else if (cell == m_cellScrollDoc) {
		[EPubSettings shared].scroll = EPubSettingsScrollDoc;
	}
	else if (cell == m_cellSyntheticSpreadAuto) {
		[EPubSettings shared].syntheticSpread = EPubSettingsSyntheticSpreadAuto;
	}
	else if (cell == m_cellSyntheticSpreadDouble) {
		[EPubSettings shared].syntheticSpread = EPubSettingsSyntheticSpreadDouble;
	}
	else if (cell == m_cellSyntheticSpreadSingle) {
		[EPubSettings shared].syntheticSpread = EPubSettingsSyntheticSpreadSingle;
	}
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

	m_cellScrollAuto.accessoryType =
		(settings.scroll == EPubSettingsScrollAuto) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	m_cellScrollContinuous.accessoryType =
		(settings.scroll == EPubSettingsScrollContinuous) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	m_cellScrollDoc.accessoryType =
		(settings.scroll == EPubSettingsScrollDoc) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	m_cellSyntheticSpreadAuto.accessoryType =
		(settings.syntheticSpread == EPubSettingsSyntheticSpreadAuto) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	m_cellSyntheticSpreadDouble.accessoryType =
		(settings.syntheticSpread == EPubSettingsSyntheticSpreadDouble) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	m_cellSyntheticSpreadSingle.accessoryType =
		(settings.syntheticSpread == EPubSettingsSyntheticSpreadSingle) ?
		UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


@end
