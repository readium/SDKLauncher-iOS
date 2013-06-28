//
//  PackageResourceCache.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/8/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@class RDPackageResource;

@interface PackageResourceCache : NSObject {
}

- (void)addResource:(RDPackageResource *)resource;
- (int)contentLengthAtRelativePath:(NSString *)relativePath;
- (NSData *)dataAtRelativePath:(NSString *)relativePath;
- (NSData *)dataAtRelativePath:(NSString *)relativePath range:(NSRange)range;
+ (PackageResourceCache *)shared;

@end
