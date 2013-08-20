//
//  HTMLUtil.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "HTMLUtil.h"


@interface HTMLUtil()

+ (NSString *)
	updateSourceAttributesInFragment:(NSString *)fragment
	relativePath:(NSString *)relativePath
	packageUUID:(NSString *)packageUUID;

@end


@implementation HTMLUtil


+ (NSString *)
	htmlByReplacingMediaURLsInHTML:(NSString *)html
	relativePath:(NSString *)relativePath
	packageUUID:(NSString *)packageUUID
{
	if (html == nil ||
		html.length == 0 ||
		relativePath == nil ||
		relativePath.length == 0 ||
		packageUUID == nil ||
		packageUUID.length == 0)
	{
		return html;
	}

	//
	// Look for 'src' attributes anywhere inside:
	//
	//   <audio ... />
	//   <video ... />
	//   <audio> ... </audio>
	//   <video> ... </video>
	//
	// Replace 'src' values with HTTP URLs that are received by our package resource server in
	// order to work around problems (bugs?) with NSURLProtocol.  For some reason, when
	// UIWebView makes a media-related request, the NSURLProtocol system does not allow it to
	// be intercepted properly.  If NSURLProtocol worked as expected, our embedded web server
	// could go away.
	//
	// See:
	//
	//   http://openradar.appspot.com/8446587
	//   http://openradar.appspot.com/8692954
	//

	for (NSString *token in @[ @"audio", @"video" ]) {
		int i = 0;

		NSString *token0 = [NSString stringWithFormat:@"<%@", token];
		NSString *token1 = [NSString stringWithFormat:@"</%@>", token];

		while (i < html.length) {
			NSRange r0 = [html rangeOfString:token0 options:0
				range:NSMakeRange(i, html.length - i)];

			if (r0.location == NSNotFound) {
				break;
			}

			i = NSMaxRange(r0);

			NSRange r1 = [html rangeOfString:@"<" options:0
				range:NSMakeRange(i, html.length - i)];

			NSRange r2 = [html rangeOfString:@">" options:0
				range:NSMakeRange(i, html.length - i)];

			if (r1.location == NSNotFound || r2.location == NSNotFound) {
				break;
			}

			if (r2.location < r1.location && [html characterAtIndex:r2.location - 1] == '/') {
				// <audio ... />
			}
			else {
				// <audio> ... </audio>

				r2 = [html rangeOfString:token1 options:0
					range:NSMakeRange(i, html.length - i)];

				if (r2.location == NSNotFound) {
					break;
				}
			}

			NSString *fragment = [self
				updateSourceAttributesInFragment:
					[html substringWithRange:NSMakeRange(i, r2.location - i)]
				relativePath:relativePath
				packageUUID:packageUUID];

			html = [[[html substringToIndex:i] stringByAppendingString:fragment]
				stringByAppendingString:[html substringFromIndex:r2.location]];

			i += fragment.length;
		}
	}

	return html;
}


+ (NSString *)readerHTML {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"reader.html" ofType:nil];
	return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}


+ (NSString *)
	updateSourceAttributesInFragment:(NSString *)fragment
	relativePath:(NSString *)relativePath
	packageUUID:(NSString *)packageUUID
{
	// Strip off the HTML file name.
	relativePath = [relativePath stringByDeletingLastPathComponent];

	int i = 0;

	while (i < fragment.length) {
		NSRange r1 = [fragment rangeOfString:@"src" options:0
			range:NSMakeRange(i, fragment.length - i)];

		if (r1.location == NSNotFound) {
			break;
		}

		i = NSMaxRange(r1);
		int indexOfEquals = -1;

		for (int j = i; j < fragment.length; j++) {
			unichar ch = [fragment characterAtIndex:j];

			if (ch == '=') {
				indexOfEquals = j;
				break;
			}

			if (ch != ' ' && ch != '\r' && ch != '\n') {
				break;
			}
		}

		if (indexOfEquals == -1) {
			continue;
		}

		i = indexOfEquals + 1;

		int indexOfApos = -1;
		int indexOfQuote = -1;

		for (int j = i; j < fragment.length; j++) {
			unichar ch = [fragment characterAtIndex:j];

			if (ch == '\'') {
				indexOfApos = j;
				break;
			}

			if (ch == '\"') {
				indexOfQuote = j;
				break;
			}

			if (ch != ' ' && ch != '\r' && ch != '\n') {
				break;
			}
		}

		int p0 = -1;
		int p1 = -1;

		if (indexOfApos != -1) {
			p0 = indexOfApos + 1;

			for (int j = p0; j < fragment.length; j++) {
				unichar ch = [fragment characterAtIndex:j];

				if (ch == '\'') {
					p1 = j;
					break;
				}
			}
		}
		else if (indexOfQuote != -1) {
			p0 = indexOfQuote + 1;

			for (int j = p0; j < fragment.length; j++) {
				unichar ch = [fragment characterAtIndex:j];

				if (ch == '\"') {
					p1 = j;
					break;
				}
			}
		}

		if (p0 == -1 || p1 == -1) {
			continue;
		}

		i = p0;

		NSString *srcValue = [fragment substringWithRange:NSMakeRange(p0, p1 - p0)];

		if ([srcValue rangeOfString:@":"].location != NSNotFound) {
			// It's probably a URL with a scheme of some kind.
			continue;
		}

		NSString *path = [relativePath stringByAppendingPathComponent:srcValue];
		NSURL *url = [NSURL fileURLWithPath:path];

		if (url == nil) {
			continue;
		}

		path = url.path;

		if ([path hasPrefix:@"/"]) {
			path = [path substringFromIndex:1];
		}

		path = [NSString stringWithFormat:@"http://localhost:%d/%@/%@",
			kSDKLauncherPackageResourceServerPort, packageUUID, path];

		fragment = [[[fragment substringToIndex:p0] stringByAppendingString:path]
			stringByAppendingString:[fragment substringFromIndex:p1]];
	}

	return fragment;
}


@end
