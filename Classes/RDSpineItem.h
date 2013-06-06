//
//  RDSpineItem.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface RDSpineItem : NSObject {
}

@property (nonatomic, readonly) NSString *baseHref;
@property (nonatomic, readonly) NSDictionary *dictionary;
@property (nonatomic, readonly) NSString *idref;
@property (nonatomic, readonly) NSString *pageSpread;
@property (nonatomic, readonly) NSString *renditionLayout;

- (id)initWithSpineItem:(void *)spineItem;

@end
