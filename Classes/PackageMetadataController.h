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
	@private UILabel *m_labelAuthors;
	@private UILabel *m_labelCopyrightOwner;
	@private UILabel *m_labelFullTitle;
	@private UILabel *m_labelISBN;
	@private UILabel *m_labelLanguage;
	@private UILabel *m_labelModificationDate;
	@private UILabel *m_labelPackageID;
	@private UILabel *m_labelSource;
	@private UILabel *m_labelSubjects;
	@private UILabel *m_labelSubtitle;
	@private UILabel *m_labelTitle;
	@private RDPackage *m_package;
	@private UIScrollView *m_scroll;
}

- (id)initWithPackage:(RDPackage *)package;

@end
