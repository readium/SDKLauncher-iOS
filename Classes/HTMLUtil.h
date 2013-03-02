//
//  HTMLUtil.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@interface HTMLUtil : NSObject

+ (NSString *)htmlByInjectingScriptIntoHTMLAtURL:(NSString *)url;

+ (NSString *)
	htmlByReplacingMediaURLsInHTML:(NSString *)html
	relativePath:(NSString *)relativePath
	packageUUID:(NSString *)packageUUID;

@end
