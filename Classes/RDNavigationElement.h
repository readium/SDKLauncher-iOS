//
//  RDNavigationElement.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/18/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface RDNavigationElement : NSObject {
	@private NSArray *m_children;
}

@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSString *title;

- (id)initWithNavigationElement:(void *)element;

@end
