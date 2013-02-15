//
//  RDPackage.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

@class RDContainer;

@interface RDPackage : NSObject {
	@private NSString *m_packageID;
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
@property (nonatomic, readonly) NSString *modificationDateString;
@property (nonatomic, readonly) NSString *packageID;
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) NSArray *spineItems;
@property (nonatomic, readonly) NSArray *subjects;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) NSString *title;

// Returns the data at the given relative path or nil if it doesn't exist.  If the data happens
// to be HTML, the out parameter is set.
- (NSData *)dataAtRelativePath:(NSString *)relativePath html:(NSString **)html;

- (id)initWithPackage:(void *)package;

@end
