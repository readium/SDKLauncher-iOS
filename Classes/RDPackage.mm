//
//  RDPackage.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackage.h"
#import "archive.h"
#import "package.h"
#import "RDSpineItem.h"


@interface RDPackage() {
	@private ePub3::Package *m_package;
}

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


- (NSData *)dataAtRelativePath:(NSString *)relativePath isHTML:(BOOL *)isHTML {
	if (isHTML != NULL) {
		*isHTML = NO;
	}

	if (relativePath == nil || relativePath.length == 0) {
		return nil;
	}

	NSRange range = [relativePath rangeOfString:@"#" options:NSBackwardsSearch];

	if (range.location != NSNotFound) {
		relativePath = [relativePath substringToIndex:range.location];
	}

	ePub3::string s = ePub3::string(relativePath.UTF8String);
	ePub3::ArchiveReader *reader = m_package->ReaderForRelativePath(s);

	if (reader == NULL) {
		NSLog(@"Relative path '%@' does not have an archive reader!", relativePath);
		return nil;
	}

	UInt8 buffer[1024];
	NSMutableData *data = [NSMutableData data];
	ssize_t readBytes = reader->read(buffer, 1024);

	while (readBytes > 0) {
		[data appendBytes:buffer length:readBytes];
		readBytes = reader->read(buffer, 1024);
	}

	// Determine if the data represents HTML.

	if (isHTML != NULL) {
		if ([m_relativePathsThatAreHTML containsObject:relativePath]) {
			*isHTML = YES;
		}
		else if (![m_relativePathsThatAreNotHTML containsObject:relativePath]) {
			ePub3::ManifestTable manifest = m_package->Manifest();

			for (auto i = manifest.begin(); i != manifest.end(); i++) {
				ePub3::ManifestItem *item = i->second;

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

	return data;
}


- (void)dealloc {
	[m_packageUUID release];
	[m_relativePathsThatAreHTML release];
	[m_relativePathsThatAreNotHTML release];
	[m_spineItems release];
	[m_subjects release];
	[super dealloc];
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

		const ePub3::SpineItem *firstSpineItem = m_package->FirstSpineItem();
		size_t count = (firstSpineItem == NULL) ? 0 : firstSpineItem->Count();
		m_spineItems = [[NSMutableArray alloc] initWithCapacity:(count == 0) ? 1 : count];

		for (size_t i = 0; i < count; i++) {
			const ePub3::SpineItem *spineItem = m_package->SpineItemAt(i);
			RDSpineItem *item = [[RDSpineItem alloc] initWithSpineItem:(void *)spineItem];
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


- (NSString *)modificationDateString {
	const ePub3::string s = m_package->ModificationDate();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)packageID {
	const ePub3::string s = m_package->PackageID();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)source {
	const ePub3::string s = m_package->Source();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)subtitle {
	const ePub3::string s = m_package->Subtitle();
	return [NSString stringWithUTF8String:s.c_str()];
}


- (NSString *)title {
	const ePub3::string s = m_package->Title();
	return [NSString stringWithUTF8String:s.c_str()];
}


@end
