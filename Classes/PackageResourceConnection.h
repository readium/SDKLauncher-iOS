//
//  PackageResourceConnection.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "AQHTTPConnection.h"

@class RDPackage;

@interface PackageResourceConnection : AQHTTPConnection

+ (void)setPackage:(RDPackage *)package;

@end
