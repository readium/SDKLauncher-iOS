//
//  RDPackage.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>
#import "RDPackageResource.h"

@class RDContainer;
@class RDNavigationElement;

@interface RDPackage : NSObject <RDPackageResourceDelegate> {
	@private RDNavigationElement *m_navElemListOfFigures;
	@private RDNavigationElement *m_navElemListOfIllustrations;
	@private RDNavigationElement *m_navElemListOfTables;
	@private RDNavigationElement *m_navElemPageList;
	@private RDNavigationElement *m_navElemTableOfContents;
	@private NSString *m_packageUUID;
	@private NSMutableSet *m_relativePathsThatAreHTML;
	@private NSMutableSet *m_relativePathsThatAreNotHTML;
	@private NSMutableArray *m_spineItems;
	@private NSMutableArray *m_subjects;
}

@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSString *basePath;
@property (nonatomic, readonly) NSString *copyrightOwner;
@property (nonatomic, readonly) NSString *fullTitle;
@property (nonatomic, readonly) NSString *isbn;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) RDNavigationElement *listOfFigures;
@property (nonatomic, readonly) RDNavigationElement *listOfIllustrations;
@property (nonatomic, readonly) RDNavigationElement *listOfTables;
@property (nonatomic, readonly) NSString *modificationDateString;
@property (nonatomic, readonly) NSString *packageID;
@property (nonatomic, readonly) NSString *packageUUID;
@property (nonatomic, readonly) RDNavigationElement *pageList;
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) NSArray *spineItems;
@property (nonatomic, readonly) NSArray *subjects;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) RDNavigationElement *tableOfContents;
@property (nonatomic, readonly) NSString *title;

- (id)initWithPackage:(void *)package;

// Returns the resource at the given relative path or nil if it doesn't exist.  The isHTML out
// parameter returns whether or not the resource is HTML.
- (RDPackageResource *)resourceAtRelativePath:(NSString *)relativePath isHTML:(BOOL *)isHTML;

@end
