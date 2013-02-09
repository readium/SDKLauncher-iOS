//
//  BaseViewController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"


@implementation BaseViewController


- (void)cleanUp {
}


- (void)dealloc {
	[self cleanUp];
	[super dealloc];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];

	if (self.isViewLoaded && !m_visible) {
		self.view = nil;
		[self cleanUp];
	}
}


- (id)initWithTitle:(NSString *)title navBarHidden:(BOOL)navBarHidden {
	m_navBarHidden = navBarHidden;

	if (self = [super initWithNibName:nil bundle:nil]) {
		self.title = title;
	}

	return self;
}


- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	m_visible = NO;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	m_visible = YES;
	UINavigationController *navController = self.navigationController;

	if (navController != nil) {
		[navController setNavigationBarHidden:m_navBarHidden animated:NO];
	}
}


@end
