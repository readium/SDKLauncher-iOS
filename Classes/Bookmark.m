//
//  Bookmark.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 4/20/13.
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

#import "Bookmark.h"


#define kKeyCFI @"CFI"
#define kKeyContainerPath @"ContainerPath"
#define kKeyIDRef @"IDRef"
#define kKeyTitle @"Title"


@implementation Bookmark


@synthesize cfi = m_cfi;
@synthesize containerPath = m_containerPath;
@synthesize idref = m_idref;
@synthesize title = m_title;


- (NSString *)description {
	return [@"Bookmark " stringByAppendingString:self.dictionary.description];
}


- (NSDictionary *)dictionary {
	return @{
		kKeyCFI : m_cfi,
		kKeyContainerPath : m_containerPath,
		kKeyIDRef : m_idref,
		kKeyTitle : m_title
	};
}


- (id)
	initWithCFI:(NSString *)cfi
	containerPath:(NSString *)containerPath
	idref:(NSString *)idref
	title:(NSString *)title
{
	if (cfi == nil ||
		cfi.length == 0 ||
		containerPath == nil ||
		containerPath.length == 0 ||
		idref == nil ||
		idref.length == 0)
	{
		return nil;
	}

	if (title == nil) {
		title = @"";
	}

	if (self = [super init]) {
		m_cfi = cfi;
		m_containerPath = containerPath;
		m_idref = idref;
		m_title = title;
	}

	return self;
}


- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		return nil;
	}

	return [self
		initWithCFI:[dictionary objectForKey:kKeyCFI]
		containerPath:[dictionary objectForKey:kKeyContainerPath]
		idref:[dictionary objectForKey:kKeyIDRef]
		title:[dictionary objectForKey:kKeyTitle]];
}


- (BOOL)isEqualToBookmark:(Bookmark *)bookmark {
	return
		bookmark != nil &&
		[bookmark.cfi isEqualToString:m_cfi] &&
		[bookmark.containerPath isEqualToString:m_containerPath] &&
		[bookmark.idref isEqualToString:m_idref] &&
		[bookmark.title isEqualToString:m_title];
}


@end
