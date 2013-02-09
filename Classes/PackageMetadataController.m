//
//  PackageMetadataController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "PackageMetadataController.h"
#import "RDPackage.h"


@interface PackageMetadataController()

- (UILabel *)addLabelWithText:(NSString *)text;

@end


@implementation PackageMetadataController


- (UILabel *)addLabelWithText:(NSString *)text {
	UILabel *label = [[[UILabel alloc] init] autorelease];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:16];
	label.numberOfLines = 0;
	label.text = text;
	label.textColor = [UIColor blackColor];
	[m_scroll addSubview:label];
	return label;
}


- (void)cleanUp {
	m_labelAuthors = nil;
	m_labelCopyrightOwner = nil;
	m_labelFullTitle = nil;
	m_labelISBN = nil;
	m_labelLanguage = nil;
	m_labelModificationDate = nil;
	m_labelSource = nil;
	m_labelSubjects = nil;
	m_labelSubtitle = nil;
	m_labelTitle = nil;
	m_scroll = nil;
}


- (void)dealloc {
	[m_package release];
	[super dealloc];
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		[self release];
		return nil;
	}

	if (self = [super initWithTitle:LocStr(@"METADATA") navBarHidden:NO]) {
		m_package = [package retain];
	}

	return self;
}


- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
	self.view.backgroundColor = [UIColor whiteColor];

	m_scroll = [[[UIScrollView alloc] init] autorelease];
	m_scroll.alwaysBounceVertical = YES;
	[self.view addSubview:m_scroll];

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

	m_labelISBN.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelISBN sizeToFit];
	y = CGRectGetMaxY(m_labelISBN.frame);

	m_labelSubjects.frame = CGRectMake(margin, y + margin, width, 1);
	[m_labelSubjects sizeToFit];
	y = CGRectGetMaxY(m_labelSubjects.frame);

	m_scroll.contentSize = CGSizeMake(size.width, y + margin);
}


@end
