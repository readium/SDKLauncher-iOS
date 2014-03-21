//
//  NavigationElementItem.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/20/14.
//  Copyright (c) 2014 The Readium Foundation. All rights reserved.
//

#import "NavigationElementItem.h"
#import "RDNavigationElement.h"


@interface NavigationElementItem () {
	@private RDNavigationElement *m_element;
	@private int m_level;
}

@end


@implementation NavigationElementItem


@synthesize element = m_element;
@synthesize level = m_level;


- (id)initWithNavigationElement:(RDNavigationElement *)element level:(int)level {
	m_level = level;

	if (element == nil) {
		return nil;
	}

	if (self = [super init]) {
		m_element = element;
	}

	return self;
}


@end
