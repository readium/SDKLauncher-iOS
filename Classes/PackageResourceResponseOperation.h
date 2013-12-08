//
//  PackageResourceResponseOperation.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 11/23/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "AQHTTPResponseOperation.h"


@class RDPackage;
@class RDPackageResource;

@interface PackageResourceResponseOperation : AQHTTPResponseOperation<AQRandomAccessFile>
{
}
- (void)initialiseData:(RDPackage *)package resource:(RDPackageResource *)resource filePath:(NSString *)fileSystemPath;
@end
