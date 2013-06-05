//
//  RDNavigationElement.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDNavigationElement.h"
#import <ePub3/nav_element.h>
#import <ePub3/nav_point.h>


@interface RDNavigationElement() {
	@private ePub3::NavigationElement *m_element;
	@private ePub3::NavigationList m_navigationList;
}

@end


@implementation RDNavigationElement


- (NSArray *)children {
	if (m_children == nil) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		m_children = array;
		m_navigationList = m_element->Children();

		for (auto i = m_navigationList.begin(); i != m_navigationList.end(); i++) {
			RDNavigationElement *element = [[RDNavigationElement alloc]
				initWithNavigationElement:i->get()];
			[array addObject:element];
			[element release];
		}
	}

	return m_children;
}


- (NSString *)content {
	ePub3::NavigationPoint *point = dynamic_cast<ePub3::NavigationPoint *>(m_element);

	if (point == nil) {
		return nil;
	}

	const ePub3::string s = point->Content();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (void)dealloc {
	[m_children release];
	[super dealloc];
}


- (id)initWithNavigationElement:(void *)element {
	if (element == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_element = (ePub3::NavigationElement *)element;
	}

	return self;
}


- (NSString *)title {
	const ePub3::string s = m_element->Title();
	return [NSString stringWithUTF8String:s.c_str()];
}


@end
