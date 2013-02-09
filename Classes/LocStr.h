//
//  LocStr.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

// Returns a localized string from the appropriate Localizable.strings file.  Accepts
// optional string formatting arguments.
NSString *LocStr(NSString *key, ...);
