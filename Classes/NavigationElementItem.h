//
//  NavigationElementItem.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/20/14.
//  Copyright (c) 2014 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDNavigationElement;

@interface NavigationElementItem : NSObject

@property (nonatomic, readonly) RDNavigationElement *element;
@property (nonatomic, readonly) int level;

- (id)initWithNavigationElement:(RDNavigationElement *)element level:(int)level;

@end
