//
//  ContainerController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/4/13.
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

#import "ContainerController.h"
#import "BookmarkDatabase.h"
#import "BookmarkListController.h"
#import "NavigationElementController.h"
#import "PackageMetadataController.h"
#import "RDContainer.h"
#import "RDPackage.h"
#import "SpineItemListController.h"

#import "RDLCPService.h"

#import <platform/apple/src/lcp.h>

//#import <LcpContentFilter.h>
#import <LcpContentModule.h>

#import "RDLcpCredentialHandler.h"
#import "RDLcpStatusDocumentHandler.h"

#import "LCPStatusDocumentProcessing_DeviceIdManager.h"

//#import "LocStr.h"
// TODO: THIS IS A HACK!! (linker complains about missing LocStr.m)
NSString *LocStr(NSString *key, ...) {
    if (key == nil) {
        NSLog(@"Got a nil key!");
    }
    else {
        NSString *s = [[NSBundle mainBundle] localizedStringForKey:key
                                                             value:nil table:nil];
        
        if (s == nil) {
            NSLog(@"Key '%@' has a nil value!", key);
        }
        else if ([s isEqualToString:key]) {
            NSLog(@"Key '%@' not found!", key);
        }
        else {
            // We found the string.  Apply the formatting arguments.
            
            va_list list;
            va_start(list, key);
            s = [[NSString alloc] initWithFormat:s arguments:list];
            va_end(list);
            
            return s;
        }
    }
    
    return @"NOT FOUND";
}

@protocol RDContainerLCPDelegate <NSObject>

- (void)decrypt:(LCPLicense*)licence container:(RDContainer*)container;
- (void)launchStatusDocumentProcessing:(LCPLicense*)licence container:(RDContainer*)container;

@end


class LcpCredentialHandler : public lcp::ICredentialHandler
{
private:
    id <RDContainerLCPDelegate> _delegate;
    RDContainer* _container;
public:
    LcpCredentialHandler(RDContainer* container, id <RDContainerLCPDelegate> delegate) {
        _container = container;
        _delegate = delegate;
    }
    
    void decrypt(lcp::ILicense *license) {
        //if (![_delegate respondsToSelector:@selector(decrypt:)]) return;
        
        LCPLicense* lcpLicense = [[LCPLicense alloc] initWithLicense:license];
        [_delegate decrypt:lcpLicense container:_container];
    }
};


class LcpStatusDocumentHandler : public lcp::IStatusDocumentHandler
{
private:
    id <RDContainerLCPDelegate> _delegate;
    RDContainer* _container;
public:
    LcpStatusDocumentHandler(RDContainer* container, id <RDContainerLCPDelegate> delegate) {
        _container = container;
        _delegate = delegate;
    }
    
    void process(lcp::ILicense *license) {
        //if (![_delegate respondsToSelector:@selector(process:)]) return;
        
        LCPLicense* lcpLicense = [[LCPLicense alloc] initWithLicense:license];
        [_delegate launchStatusDocumentProcessing:lcpLicense container:_container];
    }
};


@interface ContainerController () <
	RDContainerDelegate,
    RDContainerLCPDelegate,
	UITableViewDataSource,
	UITableViewDelegate,
	UIAlertViewDelegate,
    StatusDocumentProcessingListener>
{
	@private RDContainer *m_container;
	@private RDPackage *m_package;
	@private __weak UITableView *m_table;
	@private NSMutableArray *m_sdkErrorMessages;
    @private NSString* _currentOpenChosenPath;
    
    @private LCPStatusDocumentProcessing * _statusDocumentProcessing;
}

- (void)onStatusDocumentProcessingComplete_:(NSObject*)nope;

@end


@implementation ContainerController


- (void)onStatusDocumentProcessingComplete_:(NSObject*)nope
{
    [self openDocumentWithPath:_currentOpenChosenPath];
}

- (void)onStatusDocumentProcessingComplete:(LCPStatusDocumentProcessing*)lsdProcessing
{
    if (_statusDocumentProcessing == nil) return;
    _statusDocumentProcessing = nil;
    
    if ([lsdProcessing wasCancelled]) return;
    
    [self performSelectorOnMainThread:@selector(onStatusDocumentProcessingComplete_:) withObject:nil waitUntilDone:NO];
    //
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //
    //    });
}

- (BOOL)container:(RDContainer *)container handleSdkError:(NSString *)message isSevereEpubError:(BOOL)isSevereEpubError {

	NSLog(@"READIUM SDK: %@\n", message);

	if (isSevereEpubError == YES)
		[m_sdkErrorMessages addObject:message];

	// never throws an exception
	return YES;
}

- (void)decrypt:(LCPLicense*)lcpLicense container:(RDContainer *)container {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _license = lcpLicense;
        [self decryptLCPLicense:container];
    });
}

- (void)launchStatusDocumentProcessing:(LCPLicense*)lcpLicense container:(RDContainer *)container {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _license = lcpLicense;
        [self processStatusDocument:container];
    });
}

//- (void)containerRegisterContentFilters:(RDContainer *)container
//{
//    [[RDLCPService sharedService] registerContentFilter];
//}

- (void)containerRegisterContentModules:(RDContainer *)container
{
    lcp::ICredentialHandler* credentialHandlerNative = new LcpCredentialHandler(container, self);
    RDLcpCredentialHandler* credentialHandler = [[RDLcpCredentialHandler alloc] initWithNative:credentialHandlerNative];
    
    lcp::IStatusDocumentHandler* statusDocumentHandlerNative = new LcpStatusDocumentHandler(container, self);
    RDLcpStatusDocumentHandler* statusDocumentHandler = [[RDLcpStatusDocumentHandler alloc] initWithNative:statusDocumentHandlerNative];
    
    [[RDLCPService sharedService] registerContentModule:credentialHandler statusDocumentHandler:statusDocumentHandler];
}

- (void) popErrorMessage
{
	NSInteger count = [m_sdkErrorMessages count];
	if (count > 0)
	{
		__block NSString *message  = [m_sdkErrorMessages firstObject];
		[m_sdkErrorMessages removeObjectAtIndex:0];

		dispatch_async(dispatch_get_main_queue(), ^{

			UIAlertView * alert =[[UIAlertView alloc]
					initWithTitle:@"EPUB warning"
						  message:message
						 delegate: self
				cancelButtonTitle:@"Ignore all"
				otherButtonTitles: nil];
			[alert addButtonWithTitle:@"Ignore"];
			[alert show];
		});
	}
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [alertView cancelButtonIndex])
	{
		[self popErrorMessage];
	}
}

- (void)openDocumentWithPath:(NSString *)path {
    
    m_sdkErrorMessages = nil;
    m_container = nil;
    m_package = nil;
    
    m_sdkErrorMessages = [[NSMutableArray alloc] initWithCapacity:0];
    
    m_container = [[RDContainer alloc] initWithDelegate:self path:path];
    
    [self popErrorMessage];
    
    if (m_container == nil) {
        self.title = @"EPUB OPEN ERROR";
        return;
    }
    
    m_package = m_container.firstPackage;
    
    // NOW WITH CONTENT MODULE
    //        if (![self loadLCPLicense:error])
    //            return nil;
    
    if (m_package == nil) {
        self.title = @"EPUB OPEN ERROR";
        return;
    }
    
    NSArray *components = path.pathComponents;
    self.title = (components == nil || components.count == 0) ? @"" : components.lastObject;
}

- (instancetype)initWithPath:(NSString *)path error:(NSError **)error {
	if (self = [super initWithTitle:nil navBarHidden:NO]) {

        _currentOpenChosenPath = path;
        [self openDocumentWithPath:path];
	}

	return self;
}

//- (BOOL)loadLCPLicense:(NSError **)error
//{
//    NSString *licenseJSON = [m_container contentsOfFileAtPath:@"META-INF/license.lcpl" encoding:NSUTF8StringEncoding];
//    if (licenseJSON) {
//        _license = [[RDLCPService sharedService] openLicense:licenseJSON error:error];
//        return (_license != nil);
//    }
//    
//    return YES;
//}

- (void)loadView {
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"METADATA");
		}
		else if (indexPath.row == 1) {
			cell.textLabel.text = LocStr(@"SPINE_ITEMS");
		}
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"LIST_OF_FIGURES");
		}
		else if (indexPath.row == 1) {
			cell.textLabel.text = LocStr(@"LIST_OF_ILLUSTRATIONS");
		}
		else if (indexPath.row == 2) {
			cell.textLabel.text = LocStr(@"LIST_OF_TABLES");
		}
		else if (indexPath.row == 3) {
			cell.textLabel.text = LocStr(@"PAGE_LIST");
		}
		else if (indexPath.row == 4) {
			cell.textLabel.text = LocStr(@"TABLE_OF_CONTENTS");
		}
	}
	else if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"BOOKMARKS_WITH_COUNT", [[BookmarkDatabase shared]
				bookmarksForContainerPath:m_container.path].count);
		}
	}

	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			PackageMetadataController *c = [[PackageMetadataController alloc]
				initWithPackage:m_package];
			[self.navigationController pushViewController:c animated:YES];
		}
		else if (indexPath.row == 1) {
			SpineItemListController *c = [[SpineItemListController alloc]
				initWithContainer:m_container package:m_package];
			[self.navigationController pushViewController:c animated:YES];
		}
	}
	else if (indexPath.section == 1) {
		NavigationElementController *c = nil;
		NSString *title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;

		if (indexPath.row == 0) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfFigures
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 1) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfIllustrations
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 2) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.listOfTables
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 3) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.pageList
				container:m_container
				package:m_package
				title:title];
		}
		else if (indexPath.row == 4) {
			c = [[NavigationElementController alloc]
				initWithNavigationElement:m_package.tableOfContents
				container:m_container
				package:m_package
				title:title];
		}

		if (c == nil) {
			[m_table deselectRowAtIndexPath:indexPath animated:YES];
		}
		else {
			[self.navigationController pushViewController:c animated:YES];
		}
	}
	if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			BookmarkListController *c = [[BookmarkListController alloc]
				initWithContainer:m_container package:m_package];

			if (c != nil) {
				[self.navigationController pushViewController:c animated:YES];
			}
		}
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return
		section == 0 ? 2 :
		section == 1 ? 5 :
		section == 2 ? 1 : 0;
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (m_table.indexPathForSelectedRow != nil) {
		[m_table deselectRowAtIndexPath:m_table.indexPathForSelectedRow animated:YES];
	}

	// Bookmarks may have been added since we were last visible, so update the bookmark
	// count within the cell if needed.

	for (UITableViewCell *cell in m_table.visibleCells) {
		NSIndexPath *indexPath = [m_table indexPathForCell:cell];

		if (indexPath.section == 2 && indexPath.row == 0) {
			cell.textLabel.text = LocStr(@"BOOKMARKS_WITH_COUNT", [[BookmarkDatabase shared]
				bookmarksForContainerPath:m_container.path].count);
		}
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // NOW WITH CONTENT MODULE
//    if (self.license && !self.license.isDecrypted) {
//        [self decryptLCPLicense];
//    }
}

- (void)processStatusDocument:(RDContainer *)container {
    
    if (_statusDocumentProcessing != nil) {
        [_statusDocumentProcessing cancel];
        _statusDocumentProcessing = nil;
    }
    
    LCPStatusDocumentProcessing_DeviceIdManager* deviceIdManager = [[LCPStatusDocumentProcessing_DeviceIdManager alloc] init_:@"APPLE iOS"];
    
    _statusDocumentProcessing = [[LCPStatusDocumentProcessing alloc] init_:[RDLCPService sharedService] epubPath:_currentOpenChosenPath license:self.license deviceIdManager:deviceIdManager];
    
    [_statusDocumentProcessing start:self];
    
}

- (void)decryptLCPLicense:(RDContainer *)container {
    
    [self askLCPUserPassphrase:^(BOOL cancelled, NSString *passphrase) {
        if (cancelled) {
            // close the container
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        } else {
            NSError *error;
            BOOL decrypted = [[RDLCPService sharedService] decryptLicense:self.license passphrase:passphrase error:&error];
            if (!decrypted) {
                if (error.code != LCPErrorDecryptionLicenseEncrypted && error.code != LCPErrorDecryptionUserPassphraseNotValid) {
                    [self presentAlertWithTitle:@"LCP Error" message:@"%@ (%d)", error.domain, error.code];
                }
                [self decryptLCPLicense:container];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self openDocumentWithPath:_currentOpenChosenPath];
                });
            }
        }
    }];
}

- (void)askLCPUserPassphrase:(void(^)(BOOL cancelled, NSString *passphrase))completion {
    NSString *message = self.license.userHint ?: @"Enter your passphrase";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"LCP Protection" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *passphraseField;
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Passphrase";
        passphraseField = textField;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(YES, nil);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completion(NO, passphraseField.text);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
