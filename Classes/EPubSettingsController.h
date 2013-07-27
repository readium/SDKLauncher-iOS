//
//  EPubSettingsController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BaseViewController.h"

@interface EPubSettingsController : BaseViewController {
	@private UILabel *m_labelColumnGap;
	@private UILabel *m_labelFontScale;
	@private UILabel *m_labelIsSyntheticSpread;
	@private UIStepper *m_stepperColumnGap;
	@private UIStepper *m_stepperFontScale;
	@private UISwitch *m_switchIsSyntheticSpread;
}

@end
