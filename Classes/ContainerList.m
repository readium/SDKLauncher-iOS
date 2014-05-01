//
//  ContainerList.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

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
