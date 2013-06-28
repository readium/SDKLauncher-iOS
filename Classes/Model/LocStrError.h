//
//  LocStrError.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

// Similar to the LocStr function but returns an NSError instead of a string.
NSError *LocStrError(NSString *key, ...);
