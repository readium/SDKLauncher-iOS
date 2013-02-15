//
//  ScriptInjector.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/15/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "ScriptInjector.h"


@implementation ScriptInjector


+ (NSString *)htmlByInjectingIntoHTMLAtURL:(NSString *)url {
	if (url == nil || url.length == 0) {
		return nil;
	}

	static NSString *template = nil;

	if (template == nil) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"reader.html" ofType:nil];
		template = [NSString stringWithContentsOfFile:path
			encoding:NSUTF8StringEncoding error:nil];
		template = [template stringByReplacingOccurrencesOfString:@"{BUNDLE}"
			withString:kSDKLauncherWebViewBundleProtocol];
		template = [template retain];
	}

	return [template stringByReplacingOccurrencesOfString:@"{URL}" withString:url];
}


@end
