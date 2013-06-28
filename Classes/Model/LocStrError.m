//
//  LocStrError.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "LocStrError.h"


NSError *LocStrError(NSString *key, ...) {
	NSString *locStr = @"NOT FOUND";

	if (key == nil) {
		NSLog(@"Got a nil key!");
	}
	else {
		NSString *s = [[NSBundle mainBundle] localizedStringForKey:key
			value:nil table:nil];

		if (s == nil) {
			NSLog(@"Key '%@' has a nil value!", key);
		}
		else if ([s isEqualToString:key]) {
			NSLog(@"Key '%@' not found!", key);
		}
		else {
			// We found the string.  Apply the formatting arguments.

			va_list list;
			va_start(list, key);
			s = [[[NSString alloc] initWithFormat:s arguments:list] autorelease];
			va_end(list);

			locStr = s;
		}
	}

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:locStr
		forKey:NSLocalizedDescriptionKey];

	return [NSError errorWithDomain:@"LocStrErrorDomain" code:0 userInfo:userInfo];
}
