//
//  ContainerList.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "ContainerList.h"


NSString * const kSDKLauncherContainerListDidChange = @"SDKLauncherContainerListDidChange";


@implementation ContainerList


- (void)checkForChanges {
	NSArray *pathsCurr = self.paths;
	BOOL didChange = NO;

	NSUInteger countCurr = pathsCurr.count;
	NSUInteger countPrev = (m_paths == nil) ? 0 : m_paths.count;

	if (countCurr != countPrev) {
		didChange = YES;
	}
	else if (countCurr > 0) {
		for (NSUInteger i = 0; i < countCurr; i++) {
			NSString *pathCurr = [pathsCurr objectAtIndex:i];
			NSString *pathPrev = [m_paths objectAtIndex:i];

			if (![pathCurr isEqualToString:pathPrev]) {
				didChange = YES;
				break;
			}
		}
	}

	if (didChange) {
		m_paths = pathsCurr;
		[[NSNotificationCenter defaultCenter] postNotificationName:
			kSDKLauncherContainerListDidChange object:self];
	}

	[self performSelector:@selector(checkForChanges) withObject:nil afterDelay:1];
}


- (id)init {
	if (self = [super init]) {
		NSString *resPath = [NSBundle mainBundle].resourcePath;
		NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
			NSUserDomainMask, YES) objectAtIndex:0];
		NSFileManager *fm = [NSFileManager defaultManager];

		for (NSString *fileName in [fm contentsOfDirectoryAtPath:resPath error:nil]) {
			if ([fileName.lowercaseString hasSuffix:@".epub"]) {
				NSString *src = [resPath stringByAppendingPathComponent:fileName];
				NSString *dst = [docsPath stringByAppendingPathComponent:fileName];

				if (![fm fileExistsAtPath:dst]) {
					[fm copyItemAtPath:src toPath:dst error:nil];
				}
			}
		}

		m_paths = self.paths;
		[self performSelector:@selector(checkForChanges) withObject:nil afterDelay:0];
	}

	return self;
}


- (NSArray *)paths {
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:16];

	NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
		NSUserDomainMask, YES) objectAtIndex:0];
	NSFileManager *fm = [NSFileManager defaultManager];

	for (NSString *fileName in [fm contentsOfDirectoryAtPath:docsPath error:nil]) {
		if ([fileName.lowercaseString hasSuffix:@".epub"]) {
			[paths addObject:[docsPath stringByAppendingPathComponent:fileName]];
		}
	}

	[paths sortUsingComparator:^NSComparisonResult(NSString *path0, NSString *path1) {
		return [path0 compare:path1];
	}];

	return paths;
}


+ (ContainerList *)shared {
	static ContainerList *shared = nil;

	if (shared == nil) {
		shared = [[ContainerList alloc] init];
	}

	return shared;
}


@end
