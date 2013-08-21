//
//  RDPackage.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackage.h"
#import <ePub3/nav_table.h>
#import <ePub3/package.h>
#import "RDNavigationElement.h"
#import "RDSpineItem.h"


@interface RDPackage() {
	@private std::vector<std::unique_ptr<ePub3::ArchiveReader>> m_archiveReaderVector;
	@private ePub3::Package *m_package;
	@private std::vector<std::shared_ptr<ePub3::SpineItem>> m_spineItemVector;
}

- (NSString *)sourceHrefForNavigationTable:(ePub3::NavigationTable *)navTable;

@end


@implementation RDPackage


@synthesize packageUUID = m_packageUUID;
@synthesize spineItems = m_spineItems;
@synthesize subjects = m_subjects;


- (NSString *)authors {
	const ePub3::string s = m_package->Authors();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)basePath {
	const ePub3::string s = m_package->BasePath();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)copyrightOwner {
	const ePub3::string s = m_package->CopyrightOwner();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (void)dealloc {
	[m_navElemListOfFigures release];
	[m_navElemListOfIllustrations release];
	[m_navElemListOfTables release];
	[m_navElemPageList release];
	[m_navElemTableOfContents release];
	[m_packageUUID release];
	[m_relativePathsThatAreHTML release];
	[m_relativePathsThatAreNotHTML release];
	[m_spineItems release];
	[m_subjects release];
	[super dealloc];
}


- (NSDictionary *)dictionary {
	NSMutableDictionary *dictRoot = [NSMutableDictionary dictionary];
	[dictRoot setObject:@"/" forKey:@"rootUrl"];
	[dictRoot setObject:[NSArray array] forKey:@"mediaOverlays"];

	NSString *s = self.renditionLayout;

	if (s != nil) {
		[dictRoot setObject:s forKey:@"rendition_layout"];
	}

	NSMutableDictionary *dictSpine = [NSMutableDictionary dictionary];
	[dictRoot setObject:dictSpine forKey:@"spine"];

	NSString *direction = @"default";
	ePub3::PageProgression pageProgression = m_package->PageProgressionDirection();

	if (pageProgression == ePub3::PageProgression::LeftToRight) {
		direction = @"ltr";
	}
	else if (pageProgression == ePub3::PageProgression::RightToLeft) {
		direction = @"rtl";
	}

	[dictSpine setObject:direction forKey:@"direction"];

	NSMutableArray *items = [NSMutableArray arrayWithCapacity:m_spineItems.count];
	[dictSpine setObject:items forKey:@"items"];

	for (RDSpineItem *spineItem in self.spineItems) {
		[items addObject:spineItem.dictionary];
	}

	return dictRoot;
}


- (NSString *)fullTitle {
	const ePub3::string s = m_package->FullTitle();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (id)initWithPackage:(void *)package {
	if (package == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_package = (ePub3::Package *)package;
		m_relativePathsThatAreHTML = [[NSMutableSet alloc] init];
		m_relativePathsThatAreNotHTML = [[NSMutableSet alloc] init];

		// Package ID.

		CFUUIDRef uuid = CFUUIDCreate(NULL);
		m_packageUUID = (NSString *)CFUUIDCreateString(NULL, uuid);
		CFRelease(uuid);

		// Spine items.

		std::shared_ptr<ePub3::SpineItem> firstSpineItem = m_package->FirstSpineItem();
		size_t count = (firstSpineItem == NULL) ? 0 : firstSpineItem->Count();
		m_spineItems = [[NSMutableArray alloc] initWithCapacity:(count == 0) ? 1 : count];

		for (size_t i = 0; i < count; i++) {
			std::shared_ptr<ePub3::SpineItem> spineItem = m_package->SpineItemAt(i);
			m_spineItemVector.push_back(spineItem);
			RDSpineItem *item = [[RDSpineItem alloc] initWithSpineItem:spineItem.get()];
			[m_spineItems addObject:item];
			[item release];
		}

		// Subjects.

		ePub3::Package::StringList vec = m_package->Subjects();
		m_subjects = [[NSMutableArray alloc] initWithCapacity:4];

		for (auto i = vec.begin(); i != vec.end(); i++) {
			ePub3::string s = *i;
			[m_subjects addObject:[NSString stringWithUTF8String:s.c_str()]];
		}
	}

	return self;
}


- (NSString *)isbn {
	const ePub3::string s = m_package->ISBN();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)language {
	const ePub3::string s = m_package->Language();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (RDNavigationElement *)listOfFigures {
	if (m_navElemListOfFigures == nil) {
		ePub3::NavigationTable *navTable = m_package->ListOfFigures().get();
		m_navElemListOfFigures = [[RDNavigationElement alloc]
			initWithNavigationElement:navTable
			sourceHref:[self sourceHrefForNavigationTable:navTable]];
	}

	return m_navElemListOfFigures;
}


- (RDNavigationElement *)listOfIllustrations {
	if (m_navElemListOfIllustrations == nil) {
		ePub3::NavigationTable *navTable = m_package->ListOfIllustrations().get();
		m_navElemListOfIllustrations = [[RDNavigationElement alloc]
			initWithNavigationElement:navTable
			sourceHref:[self sourceHrefForNavigationTable:navTable]];
	}

	return m_navElemListOfIllustrations;
}


- (RDNavigationElement *)listOfTables {
	if (m_navElemListOfTables == nil) {
		ePub3::NavigationTable *navTable = m_package->ListOfTables().get();
		m_navElemListOfTables = [[RDNavigationElement alloc]
			initWithNavigationElement:navTable
			sourceHref:[self sourceHrefForNavigationTable:navTable]];
	}

	return m_navElemListOfTables;
}


- (NSString *)modificationDateString {
	const ePub3::string s = m_package->ModificationDate();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)packageID {
	const ePub3::string s = m_package->PackageID();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (RDNavigationElement *)pageList {
	if (m_navElemPageList == nil) {
		ePub3::NavigationTable *navTable = m_package->PageList().get();
		m_navElemPageList = [[RDNavigationElement alloc]
			initWithNavigationElement:navTable
			sourceHref:[self sourceHrefForNavigationTable:navTable]];
	}

	return m_navElemPageList;
}


- (void)rdpackageResourceWillDeallocate:(RDPackageResource *)packageResource {
	for (auto i = m_archiveReaderVector.begin(); i != m_archiveReaderVector.end(); i++) {
		if (i->get() == packageResource.archiveReader) {
			m_archiveReaderVector.erase(i);
			return;
		}
	}

	NSLog(@"The archive reader was not found!");
}


- (NSString *)renditionLayout {
	ePub3::PropertyPtr prop = m_package->PropertyMatching("layout", "rendition");
	return (prop == nullptr) ? @"" : [NSString stringWithUTF8String:prop->Value().c_str()];
}


- (RDPackageResource *)resourceAtRelativePath:(NSString *)relativePath isHTML:(BOOL *)isHTML {
	if (isHTML != NULL) {
		*isHTML = NO;
	}

	if (relativePath == nil || relativePath.length == 0) {
		return nil;
	}

	NSRange range = [relativePath rangeOfString:@"#"];

	if (range.location != NSNotFound) {
		relativePath = [relativePath substringToIndex:range.location];
	}

	ePub3::string s = ePub3::string(relativePath.UTF8String);
	std::unique_ptr<ePub3::ArchiveReader> reader = m_package->ReaderForRelativePath(s);

	if (reader == nullptr) {
		NSLog(@"Relative path '%@' does not have an archive reader!", relativePath);
		return nil;
	}

	RDPackageResource *resource = [[[RDPackageResource alloc]
		initWithDelegate:self
		archiveReader:reader.get()
		relativePath:relativePath] autorelease];

	if (resource != nil) {
		m_archiveReaderVector.push_back(std::move(reader));
	}

	// Determine if the data represents HTML.

	if (isHTML != NULL) {
		if ([m_relativePathsThatAreHTML containsObject:relativePath]) {
			*isHTML = YES;
		}
		else if (![m_relativePathsThatAreNotHTML containsObject:relativePath]) {
			ePub3::ManifestTable manifest = m_package->Manifest();

			for (auto i = manifest.begin(); i != manifest.end(); i++) {
				std::shared_ptr<ePub3::ManifestItem> item = i->second;

				if (item->Href() == s) {
					if (item->MediaType() == "application/xhtml+xml") {
						[m_relativePathsThatAreHTML addObject:relativePath];
						*isHTML = YES;
					}

					break;
				}
			}

			if (*isHTML == NO) {
				[m_relativePathsThatAreNotHTML addObject:relativePath];
			}
		}
	}

	return resource;
}


- (NSString *)source {
	const ePub3::string s = m_package->Source();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)sourceHrefForNavigationTable:(ePub3::NavigationTable *)navTable {
	if (navTable == nil) {
		return nil;
	}

	const ePub3::string s = navTable->SourceHref();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)subtitle {
	const ePub3::string s = m_package->Subtitle();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (RDNavigationElement *)tableOfContents {
	if (m_navElemTableOfContents == nil) {
		ePub3::NavigationTable *navTable = m_package->TableOfContents().get();
		m_navElemTableOfContents = [[RDNavigationElement alloc]
			initWithNavigationElement:navTable
			sourceHref:[self sourceHrefForNavigationTable:navTable]];
	}

	return m_navElemTableOfContents;
}


- (NSString *)title {
	const ePub3::string s = m_package->Title();
	return [NSString stringWithUTF8String:s.c_str()];
}


@end
