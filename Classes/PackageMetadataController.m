//
//  PackageMetadataController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
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

#import "PackageMetadataController.h"
#import "RDPackage.h"


@interface PackageMetadataController()

- (UILabel *)addLabelWithText:(NSString *)text;

@end


@implementation PackageMetadataController


- (UILabel *)addLabelWithText:(NSString *)text {
	UILabel *label = [[UILabel alloc] init];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:16];
	label.numberOfLines = 0;
	label.text = text;
	label.textColor = [UIColor blackColor];
	[m_scroll addSubview:label];
	return label;
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"METADATA") navBarHidden:NO]) {
		m_package = package;
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];
	self.view.backgroundColor = [UIColor whiteColor];

	UIScrollView *scroll = [[UIScrollView alloc] init];
	m_scroll = scroll;
	scroll.alwaysBounceVertical = YES;
	[self.view addSubview:scroll];

	m_labelTitle = [self addLabelWithText:
		LocStr(@"METADATA_TITLE", m_package.title)];

	m_labelFullTitle = [self addLabelWithText:
		LocStr(@"METADATA_FULL_TITLE", m_package.fullTitle)];

	m_labelSubtitle = [self addLabelWithText:
		LocStr(@"METADATA_SUBTITLE", m_package.subtitle)];

	m_labelAuthors = [self addLabelWithText:
		LocStr(@"METADATA_AUTHORS", m_package.authors)];

	m_labelLanguage = [self addLabelWithText:
		LocStr(@"METADATA_LANGUAGE", m_package.language)];

	m_labelSource = [self addLabelWithText:
		LocStr(@"METADATA_SOURCE", m_package.source)];

	m_labelCopyrightOwner = [self addLabelWithText:
		LocStr(@"METADATA_COPYRIGHT_OWNER", m_package.copyrightOwner)];

	m_labelModificationDate = [self addLabelWithText:
		LocStr(@"METADATA_MODIFICATION_DATE", m_package.modificationDateString)];

	m_labelPackageID = [self addLabelWithText:
		LocStr(@"METADATA_PACKAGE_ID", m_package.packageID)];

	m_labelISBN = [self addLabelWithText:
		LocStr(@"METADATA_ISBN", m_package.isbn)];

	m_labelSubjects = [self addLabelWithText:
		LocStr(@"METADATA_SUBJECTS", [m_package.subjects componentsJoinedByString:@", "])];
}


- (void)viewDidLayoutSubviews {
	CGSize size = self.view.bounds.size;
	CGFloat margin = 16;
	CGFloat y = 0;
	CGFloat width = size.width - 2.0 * margin;

	m_scroll.frame = self.view.bounds;

	m_labelTitle.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelTitle sizeToFit];
	y = CGRectGetMaxY(m_labelTitle.frame);

	m_labelFullTitle.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelFullTitle sizeToFit];
	y = CGRectGetMaxY(m_labelFullTitle.frame);

	m_labelSubtitle.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelSubtitle sizeToFit];
	y = CGRectGetMaxY(m_labelSubtitle.frame);

	m_labelAuthors.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelAuthors sizeToFit];
	y = CGRectGetMaxY(m_labelAuthors.frame);

	m_labelLanguage.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelLanguage sizeToFit];
	y = CGRectGetMaxY(m_labelLanguage.frame);

	m_labelSource.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelSource sizeToFit];
	y = CGRectGetMaxY(m_labelSource.frame);

	m_labelCopyrightOwner.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelCopyrightOwner sizeToFit];
	y = CGRectGetMaxY(m_labelCopyrightOwner.frame);

	m_labelModificationDate.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelModificationDate sizeToFit];
	y = CGRectGetMaxY(m_labelModificationDate.frame);

	m_labelPackageID.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelPackageID sizeToFit];
	y = CGRectGetMaxY(m_labelPackageID.frame);

	m_labelISBN.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelISBN sizeToFit];
	y = CGRectGetMaxY(m_labelISBN.frame);

	m_labelSubjects.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelSubjects sizeToFit];
	y = CGRectGetMaxY(m_labelSubjects.frame);

	m_scroll.contentSize = CGSizeMake(size.width, y + margin);
}


@end
