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


@interface EPubSettingsController ()

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
				action:@selector(onClickDone)];
		}

		// Synthetic spread

		UISwitch *sw = [[UISwitch alloc] init];
		sw.on = [EPubSettings shared].isSyntheticSpread;
		[sw addTarget:self action:@selector(onIsSyntheticSpreadDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellIsSyntheticSpread = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil];
		m_cellIsSyntheticSpread.accessoryView = sw;
		m_cellIsSyntheticSpread.textLabel.text = LocStr(@"EPUB_SETTINGS_IS_SYNTHETIC_SPREAD");

		// Font scale

		UIStepper *stepper = [[UIStepper alloc] init];
		stepper.minimumValue = 0.2;
		stepper.maximumValue = 5;
		stepper.stepValue = 0.1;
		stepper.value = [EPubSettings shared].fontScale;
		[stepper addTarget:self action:@selector(onFontScaleDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellFontScale = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil];
		m_cellFontScale.accessoryView = stepper;

		// Column gap

		int maxValue = MIN(SCREEN_SIZE.width, SCREEN_SIZE.height) / 3.0;
		int stepValue = 5;

		while (maxValue % stepValue != 0) {
			maxValue--;
		}

		stepper = [[UIStepper alloc] init];
		stepper.minimumValue = 0;
		stepper.maximumValue = maxValue;
		stepper.stepValue = stepValue;
		stepper.value = [EPubSettings shared].columnGap;
		[stepper addTarget:self action:@selector(onColumnGapDidChange:)
			forControlEvents:UIControlEventValueChanged];

		m_cellColumnGap = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:nil];
		m_cellColumnGap.accessoryView = stepper;

		// Finish up

		m_cells = @[
			m_cellIsSyntheticSpread,
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
	[self.view addSubview:table];
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
