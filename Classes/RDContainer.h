//
//  RDContainer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface RDContainer : NSObject {
	@private NSMutableArray *m_packages;
}

@property (nonatomic, readonly) NSArray *packages;

- (id)initWithPath:(NSString *)path;

@end
