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


@interface ContainerListController ()
#if ENABLE_NET_PROVIDER
<LCPAcquisitionDelegate>
#else
<NSURLSessionDataDelegate>
#endif //ENABLE_NET_PROVIDER

#if ENABLE_NET_PROVIDER
@property (strong, nonatomic) NSURLSession *session;

@property (strong, nonatomic) NSMutableDictionary *sessionDownloadPaths;
@property (strong, nonatomic) NSMutableDictionary *sessionSuggestedFilenames;
// @property (strong, nonatomic) NSMutableDictionary *sessionLCPPaths;
#endif //ENABLE_NET_PROVIDER

@end


@implementation ContainerListController


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"CONTAINER_LIST_TITLE") navBarHidden:NO]) {
		m_paths = [ContainerList shared].paths;
        m_lcpAcquisitions = [NSMutableDictionary dictionary];
        
#if !ENABLE_NET_PROVIDER
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        
        _sessionDownloadPaths = [NSMutableDictionary dictionary];
        _sessionSuggestedFilenames = [NSMutableDictionary dictionary];
        // _sessionLCPPaths = [NSMutableDictionary dictionary]; // see m_lcpAcquisitions
#endif //!ENABLE_NET_PROVIDER
        
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
        
#if ENABLE_NET_PROVIDER
        LCPAcquisition *acquisition = m_lcpAcquisitions[path];
        if (acquisition) {
            success = YES;
            [acquisition cancel];
        } else {
            success = [self acquirePublicationWithLicense:path error:&error];
        }
#else
        NSURLSessionDataTask *task = m_lcpAcquisitions[path];
        if (task) {
            success = YES;
            [task cancel];
        } else {
            success = [self acquirePublicationWithLicense:path error:&error];
        }
#endif //ENABLE_NET_PROVIDER
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

#if ENABLE_NET_PROVIDER
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"lcp.epub"];
    NSURL *downloadFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    LCPAcquisition *acquisition = [lcp createAcquisition:license publicationPath:downloadFileURL.path error:error];
    if (!acquisition)
        return NO;
    
    m_lcpAcquisitions[licensePath] = acquisition;
    [acquisition startWithDelegate:self];
#else

    NSURL *sourceUrl = [NSURL URLWithString:license.linkPublication];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:sourceUrl];
//        id identifier = @(task.taskIdentifier);
//        self.requests[identifier] = [NSValue valueWithPointer:request];
//        self.callbacks[identifier] = [NSValue valueWithPointer:callback];
    
    m_lcpAcquisitions[licensePath] = task;
    [task resume];
    
#endif //ENABLE_NET_PROVIDER
    
    return YES;
}




#if ENABLE_NET_PROVIDER

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

        // move the downloaded publication to the Documents/ folder, using
        // the suggested filename if any
        NSString *licensePath = [self pathForAcquisition:acquisition];
        NSString *filename = (acquisition.suggestedFilename.length > 0) ? acquisition.suggestedFilename : [licensePath lastPathComponent];
        filename = [NSString stringWithFormat:@"%@.epub", [filename stringByDeletingPathExtension]];
        
        NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSString *destinationPath = [[documentsURL URLByAppendingPathComponent:filename] path];
        
        [[NSFileManager defaultManager] moveItemAtPath:acquisition.publicationPath toPath:destinationPath error:NULL];
        
        // [[NSFileManager defaultManager] removeItemAtPath:licensePath error:NULL];
    
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endAcquisition:acquisition];
        });
    });
}

#else

- (NSString *)pathForAcquisition:(NSURLSessionDataTask *)task
{
    return [[m_lcpAcquisitions allKeysForObject:task] firstObject];
}

- (void)endAcquisition:(NSURLSessionDataTask *)task
{
    NSString *path = [self pathForAcquisition:task];
    [self setCellProgress:0 forPath:path];
    [m_lcpAcquisitions removeObjectForKey:path];
}

- (void)getSessionInfo:(NSString **)sessionDownloadPath
    sessionSuggestedFilename:(NSString **)sessionSuggestedFilename
    //sessionLCPPath:(NSString**)sessionLCPPath
    forTask:(NSURLSessionTask *)task
{
    id identifier = @(task.taskIdentifier);

    if (sessionDownloadPath != NULL) {
        *sessionDownloadPath = (NSString *)[self.sessionDownloadPaths[identifier] pointerValue];
    }

    if (sessionSuggestedFilename != NULL) {
        *sessionSuggestedFilename = (NSString *)[self.sessionSuggestedFilenames[identifier] pointerValue];
    }
    //
    // if (sessionLCPPath != NULL) {
    //     *sessionLCPPath = (NSString *)[self.sessionLCPPaths[identifier] pointerValue];
    // }
    
}

- (void)taskEnded:(NSURLSessionTask *)task
{
    id identifier = @(task.taskIdentifier);
    [self.sessionDownloadPaths removeObjectForKey:identifier];
    [self.sessionSuggestedFilenames removeObjectForKey:identifier];
    // [self.sessionLCPPaths removeObjectForKey:identifier];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    id identifier = @(dataTask.taskIdentifier);
    
    NSString *sessionDownloadPath;
    NSString *sessionSuggestedFilename;
    // NSString *sessionLCPPath;
    [self getSessionInfo:&sessionDownloadPath
        sessionSuggestedFilename:&sessionSuggestedFilename
        // sessionLCPPath:&sessionLCPPath
        forTask:dataTask];
    
    NSString *sessionLCPPath = [self pathForAcquisition:dataTask];
    
    if (!sessionLCPPath)
        return;
    
    NSString *filePath;
    
    NSString *filename = response.suggestedFilename;
    if (filename.length > 0) {
        self.sessionSuggestedFilenames[identifier] = [NSValue valueWithPointer:filename];
    }
    
    if (false && // better to name file to match LCPL
        filename.length > 0) {
        
        NSString *folderPath = [sessionLCPPath stringByDeletingLastPathComponent];
        filePath = [folderPath stringByAppendingPathComponent:filename];
//       filePath = [NSString stringWithFormat:@"%@%@%@", sessionLCPPath, @"_", filename];
    } else {
        filePath = [NSString stringWithFormat:@"%@%@", sessionLCPPath, @".epub"];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    }
    
    self.sessionDownloadPaths[identifier] = [NSValue valueWithPointer:filePath];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data
{
    NSString *sessionDownloadPath;
    NSString *sessionSuggestedFilename;
    // NSString *sessionLCPPath;
    [self getSessionInfo:&sessionDownloadPath
        sessionSuggestedFilename:&sessionSuggestedFilename
        // sessionLCPPath:&sessionLCPPath
        forTask:task];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sessionDownloadPath]) {
        [data writeToFile:sessionDownloadPath atomically:YES];
    } else {
        // TODO: keep handle alive to avoid lots of open/close
        //(const unsigned char *)data.bytes
        //data.length
        //getSessionInfo() for sessionDownloadFileHandle?
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:sessionDownloadPath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
    
    float progress = -1;
    float received = task.countOfBytesReceived;
    float expected = task.countOfBytesExpectedToReceive;
    if (expected > 0) {
        progress = received / expected;
    }

    NSString *path = [self pathForAcquisition:task];
    [self setCellProgress:progress forPath:path];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *sessionDownloadPath;
    NSString *sessionSuggestedFilename;
    [self getSessionInfo:&sessionDownloadPath sessionSuggestedFilename:&sessionSuggestedFilename forTask:task];
    if (!sessionDownloadPath)
        return;
    
    
    NSInteger code = [(NSHTTPURLResponse *)task.response statusCode];
    
    if (error) {
        [self presentAlertWithTitle:@"Cannot Download Publication" message:@"%@ (%d) (%li)", error.domain, error.code, code];
        
        [self taskEnded:task];
        [self endAcquisition:task];
    } else if (code < 200 || code >= 300) {

        [self presentAlertWithTitle:@"Cannot Download Publication" message:@"(%li)", code];
        
        [self taskEnded:task];
        [self endAcquisition:task];
    } else {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            // move the downloaded publication to the Documents/ folder, using
            // the suggested filename if any
            NSString *licensePath = [self pathForAcquisition:task];
            NSString *filename = (sessionSuggestedFilename != nil && sessionSuggestedFilename.length > 0) ? sessionSuggestedFilename : [licensePath lastPathComponent];
            filename = [NSString stringWithFormat:@"%@.epub", [filename stringByDeletingPathExtension]];
        
            NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSString *destinationPath = [[documentsURL URLByAppendingPathComponent:filename] path];
        
            // [[NSFileManager defaultManager] moveItemAtPath:sessionDownloadPath toPath:destinationPath error:NULL];
        
            // [[NSFileManager defaultManager] removeItemAtPath:licensePath error:NULL];
        
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [self taskEnded:task];
                [self endAcquisition:task];
            });
        });
    }
    
    
}

#endif //ENABLE_NET_PROVIDER


@end
