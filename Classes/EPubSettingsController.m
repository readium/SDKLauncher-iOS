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

- (UILabel *)addLabelWithText:(NSString *)text;
- (void)updateLabels;

@end


@implementation EPubSettingsController


- (UILabel *)addLabelWithText:(NSString *)text {
	UILabel *label = [[[UILabel alloc] init] autorelease];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont boldSystemFontOfSize:18];
	label.text = text;
	label.textColor = [UIColor blackColor];
	[label sizeToFit];
	[self.view addSubview:label];
	return label;
}


- (void)cleanUp {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	m_labelColumnGap = nil;
	m_labelFontScale = nil;
	m_labelIsSyntheticSpread = nil;
	m_stepperColumnGap = nil;
	m_stepperFontScale = nil;
	m_switchIsSyntheticSpread = nil;
}


- (void)dealloc {
	[super dealloc];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"EPUB_SETTINGS_TITLE") navBarHidden:NO]) {
		self.contentSizeForViewInPopover = CGSizeMake(320, 150);

		if (!IS_IPAD) {
			self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone
				target:self
				action:@selector(onClickDone)] autorelease];
		}
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
	self.view.backgroundColor = [UIColor whiteColor];

	m_labelColumnGap = [self addLabelWithText:@"X"];
	m_labelFontScale = [self addLabelWithText:@"X"];
	m_labelIsSyntheticSpread = [self addLabelWithText:LocStr(@"EPUB_SETTINGS_IS_SYNTHETIC_SPREAD")];

	[self updateLabels];

	// Column gap stepper

	int minValue = 0;
	int maxValue = MIN(SCREEN_SIZE.width, SCREEN_SIZE.height) / 3.0;
	int stepValue = 5;

	while (maxValue % stepValue != 0) {
		maxValue--;
	}

	m_stepperColumnGap = [[[UIStepper alloc] init] autorelease];
	m_stepperColumnGap.minimumValue = minValue;
	m_stepperColumnGap.maximumValue = maxValue;
	m_stepperColumnGap.stepValue = stepValue;
	m_stepperColumnGap.value = [EPubSettings shared].columnGap;
	[m_stepperColumnGap addTarget:self action:@selector(onStepperDidChange:)
		forControlEvents:UIControlEventValueChanged];
	[m_stepperColumnGap sizeToFit];
	[self.view addSubview:m_stepperColumnGap];

	// Font scale stepper

	m_stepperFontScale = [[[UIStepper alloc] init] autorelease];
	m_stepperFontScale.minimumValue = 0.2;
	m_stepperFontScale.maximumValue = 5;
	m_stepperFontScale.stepValue = 0.1;
	m_stepperFontScale.value = [EPubSettings shared].fontScale;
	[m_stepperFontScale addTarget:self action:@selector(onStepperDidChange:)
		forControlEvents:UIControlEventValueChanged];
	[m_stepperFontScale sizeToFit];
	[self.view addSubview:m_stepperFontScale];

	// Switch

	m_switchIsSyntheticSpread = [[[UISwitch alloc] init] autorelease];
	m_switchIsSyntheticSpread.on = [EPubSettings shared].isSyntheticSpread;
	[m_switchIsSyntheticSpread addTarget:self action:@selector(onSwitchDidChange:)
		forControlEvents:UIControlEventValueChanged];
	[m_switchIsSyntheticSpread sizeToFit];
	[self.view addSubview:m_switchIsSyntheticSpread];

	// Notifications

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(updateLabels)
		name:kSDKLauncherEPubSettingsDidChange
		object:nil];
}


- (void)onClickDone {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)onStepperDidChange:(UIStepper *)stepper {
	if (stepper == m_stepperColumnGap) {
		[EPubSettings shared].columnGap = stepper.value;
	}
	else if (stepper == m_stepperFontScale) {
		[EPubSettings shared].fontScale = stepper.value;
	}
}


- (void)onSwitchDidChange:(UISwitch *)sw {
	if (sw == m_switchIsSyntheticSpread) {
		[EPubSettings shared].isSyntheticSpread = sw.on;
	}
}


- (void)updateLabels {
	EPubSettings *settings = [EPubSettings shared];

	m_labelColumnGap.text = LocStr(@"EPUB_SETTINGS_COLUMN_GAP",
		(int)round(settings.columnGap));

	m_labelFontScale.text = LocStr(@"EPUB_SETTINGS_FONT_SCALE",
		(int)round(100.0 * settings.fontScale));
}


- (void)viewDidLayoutSubviews {
	CGSize size = self.view.bounds.size;
	CGFloat marginLR = 12;
	CGFloat gap = 24;

	m_labelIsSyntheticSpread.frame = CGRectMake(marginLR, 16, size.width - 2.0 * marginLR,
		m_labelIsSyntheticSpread.bounds.size.height);
	CGFloat y = CGRectGetMaxY(m_labelIsSyntheticSpread.frame);

	m_labelFontScale.frame = CGRectMake(marginLR, y + gap, size.width - 2.0 * marginLR,
		m_labelFontScale.bounds.size.height);
	y = CGRectGetMaxY(m_labelFontScale.frame);

	m_labelColumnGap.frame = CGRectMake(marginLR, y + gap, size.width - 2.0 * marginLR,
		m_labelColumnGap.bounds.size.height);
	y = CGRectGetMaxY(m_labelColumnGap.frame);

	m_switchIsSyntheticSpread.frame = CGRectOffset(m_switchIsSyntheticSpread.bounds,
		size.width - marginLR - m_switchIsSyntheticSpread.bounds.size.width,
		round(CGRectGetMidY(m_labelIsSyntheticSpread.frame) -
			0.5 * m_switchIsSyntheticSpread.bounds.size.height));

	m_stepperFontScale.frame = CGRectOffset(m_stepperFontScale.bounds,
		size.width - marginLR - m_stepperFontScale.bounds.size.width,
		round(CGRectGetMidY(m_labelFontScale.frame) - 0.5 * m_stepperFontScale.bounds.size.height));

	m_stepperColumnGap.frame = CGRectOffset(m_stepperColumnGap.bounds,
		size.width - marginLR - m_stepperColumnGap.bounds.size.width,
		round(CGRectGetMidY(m_labelColumnGap.frame) - 0.5 * m_stepperColumnGap.bounds.size.height));
}


@end
