//
//  EPubSettingsController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 7/27/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "BaseViewController.h"

@interface EPubSettingsController : BaseViewController <UITableViewDataSource> {
	@private UITableViewCell *m_cellColumnGap;
	@private UITableViewCell *m_cellFontScale;
	@private UITableViewCell *m_cellIsSyntheticSpread;
	@private NSArray *m_cells;
	@private __weak UITableView *m_table;
}

@end
