//
//  BaseViewController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController {
	@private BOOL m_navBarHidden;
	@private BOOL m_visible;
}

- (void)cleanUp;
- (id)initWithTitle:(NSString *)title navBarHidden:(BOOL)navBarHidden;

@end
