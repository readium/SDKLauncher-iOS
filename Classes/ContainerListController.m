//
//  ContainerListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
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

#import "ContainerListController.h"
#import "ContainerController.h"
#import "ContainerList.h"
#import "RDLCPService.h"
#import <platform/apple/src/lcp.h>


static NSInteger const kAcquisitionProgressBar = 3208;


@interface ContainerListController () <LCPAcquisitionDelegate>
@end


@implementation ContainerListController


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"CONTAINER_LIST_TITLE") navBarHidden:NO]) {
		m_paths = [ContainerList shared].paths;
        m_lcpAcquisitions = [NSMutableDictionary dictionary];

		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(onContainerListDidChange)
			name:kSDKLauncherContainerListDidChange object:nil];
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (void)onContainerListDidChange {
	m_paths = [ContainerList shared].paths;
	[m_table reloadData];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
    
	NSString *path = [m_paths objectAtIndex:indexPath.row];
    
    cell.textLabel.text = path.lastPathComponent;
    
    if ([[ContainerList shared] canOpenFile:path]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // LCPL acquisition progress bar
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progress.tag = kAcquisitionProgressBar;
    progress.progress = 0;
    progress.trackTintColor = [UIColor clearColor];
    progress.progressTintColor = [[UIColor greenColor] colorWithAlphaComponent:0.1];
    progress.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView insertSubview:progress atIndex:0];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[progress]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(progress)]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progress]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(progress)]];
    
	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString *path = [m_paths objectAtIndex:indexPath.row];
    
    BOOL success = NO;
    NSString *errorTitle = @"Cannot Open Book";
    NSError *error;
    
    if ([[ContainerList shared] canOpenFile:path]) {
        ContainerController *c = [[ContainerController alloc] initWithPath:path error:&error];
        if (c) {
            success = YES;
            [self.navigationController pushViewController:c animated:YES];
        }
        
    } else if ([path.pathExtension.lowercaseString isEqual:@"lcpl"]) {
        errorTitle = @"Cannot Download Publication";
        
        LCPAcquisition *acquisition = m_lcpAcquisitions[path];
        if (acquisition) {
            success = YES;
            [acquisition cancel];
        } else {
            success = [self acquirePublicationWithLicense:path error:&error];
        }
    }
    
    if (!success) {
        NSString *message = error ? [NSString stringWithFormat:@"%@ (%ld)", error.domain, (long)error.code] : nil;
        [self presentAlertWithTitle:errorTitle message:message];
    }
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_paths.count;
}

- (UITableViewCell *)cellForPath:(NSString *)path {
    NSUInteger index = [m_paths indexOfObject:path];
    if (index == NSNotFound)
        return nil;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [m_table cellForRowAtIndexPath:indexPath];
}

- (void)setCellProgress:(CGFloat)progress forPath:(NSString *)path {
    UITableViewCell *cell = [self cellForPath:path];
    
    for (UIView *subview in cell.contentView.subviews) {
        if (subview.tag == kAcquisitionProgressBar) {
            ((UIProgressView *)subview).progress = progress;
            break;
        }
    }
}

- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


//////////////////////////////////////////////////////////////////////
#pragma mark - LCP Acquisition

- (BOOL)acquirePublicationWithLicense:(NSString *)licensePath error:(NSError **)error {
    RDLCPService *lcp = [RDLCPService sharedService];
    NSString *licenseJSON = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];
    
    LCPLicense *license = [lcp openLicense:licenseJSON error:error];
    if (!license)
        return NO;
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"lcp.epub"];
    NSURL *downloadFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    LCPAcquisition *acquisition = [lcp createAcquisition:license publicationPath:downloadFileURL.path error:error];
    if (!acquisition)
        return NO;
    
    m_lcpAcquisitions[licensePath] = acquisition;
    [acquisition startWithDelegate:self];
    
    return YES;
}

- (NSString *)pathForAcquisition:(LCPAcquisition *)acquisition
{
    return [[m_lcpAcquisitions allKeysForObject:acquisition] firstObject];
}

- (void)endAcquisition:(LCPAcquisition *)acquisition
{
    NSString *path = [self pathForAcquisition:acquisition];
    [self setCellProgress:0 forPath:path];
    [m_lcpAcquisitions removeObjectForKey:path];
}

- (void)lcpAcquisitionDidCancel:(LCPAcquisition *)acquisition
{
    [self endAcquisition:acquisition];
}

- (void)lcpAcquisition:(LCPAcquisition *)acquisition didProgress:(float)progress
{
    NSString *path = [self pathForAcquisition:acquisition];
    [self setCellProgress:progress forPath:path];
}

- (void)lcpAcquisition:(LCPAcquisition *)acquisition didEnd:(BOOL)success error:(NSError *)error
{
    if (!success) {
        [self presentAlertWithTitle:@"Cannot Download Publication" message:@"%@ (%d)", error.domain, error.code];
        [self endAcquisition:acquisition];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (success) {
            // move the downloaded publication to the Documents/ folder, using
            // the suggested filename if any
            NSString *licensePath = [self pathForAcquisition:acquisition];
            NSString *filename = (acquisition.suggestedFilename.length > 0) ? acquisition.suggestedFilename : [licensePath lastPathComponent];
            filename = [NSString stringWithFormat:@"%@.epub", [filename stringByDeletingPathExtension]];
            
            NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSString *destinationPath = [[documentsURL URLByAppendingPathComponent:filename] path];
            
            [[NSFileManager defaultManager] moveItemAtPath:acquisition.publicationPath toPath:destinationPath error:NULL];
            
            [[NSFileManager defaultManager] removeItemAtPath:licensePath error:NULL];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endAcquisition:acquisition];
        });
    });
}

@end
