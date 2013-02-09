//
//  ContainerList.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

extern NSString * const kSDKLauncherContainerListDidChange;

@interface ContainerList : NSObject {
	@private NSArray *m_paths;
}

@property (nonatomic, readonly) NSArray *paths;

+ (ContainerList *)shared;

@end
