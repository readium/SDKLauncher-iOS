//
//  PackageMetadataController.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/6/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "BaseViewController.h"

@class RDPackage;

@interface PackageMetadataController : BaseViewController {
	@private __weak UILabel *m_labelAuthors;
	@private __weak UILabel *m_labelCopyrightOwner;
	@private __weak UILabel *m_labelFullTitle;
	@private __weak UILabel *m_labelISBN;
	@private __weak UILabel *m_labelLanguage;
	@private __weak UILabel *m_labelModificationDate;
	@private __weak UILabel *m_labelPackageID;
	@private __weak UILabel *m_labelSource;
	@private __weak UILabel *m_labelSubjects;
	@private __weak UILabel *m_labelSubtitle;
	@private __weak UILabel *m_labelTitle;
	@private RDPackage *m_package;
	@private __weak UIScrollView *m_scroll;
}

- (id)initWithPackage:(RDPackage *)package;

@end
