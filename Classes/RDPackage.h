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

- (NSData *)dataAtRelativePath:(NSString *)relativePath;
- (id)initWithPackage:(void *)package;

@end
