//
//  ScriptInjector.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/15/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface ScriptInjector : NSObject

+ (NSString *)htmlByInjectingIntoHTMLAtURL:(NSString *)url;

@end
