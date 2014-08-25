//
//  FootnoteViewController.m
//  SDKLauncher-iOS
//
//  Created by Mickaël Menu on 8/25/14.
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

#import "FootnoteViewController.h"

static NSString *const HTMLContentTemplate = @"<html><body style='text-align: justify;'>%@</body></html>";

@interface FootnoteViewController ()
@property (copy, nonatomic) NSString *content;
@property (strong, nonatomic) UIViewController *hostViewController;
@end

@implementation FootnoteViewController

- (id)initWithTitle:(NSString *)title content:(NSString *)content
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _content = [content copy];
        
        self.title = title;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [self.titleBar.topItem setTitle:self.title];
    
    [self.loadingIndicator startAnimating];
    [self.webView loadHTMLString:self.content baseURL:nil];
}

- (void)close:(id)sender
{
    [self.hostViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showWithHost:(UIViewController *)hostViewController
{
    _hostViewController = hostViewController;
    [hostViewController presentViewController:self animated:YES completion:nil];
}


//////////////////////////////////////////////////////////////////////
#pragma mark - Web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.loadingIndicator stopAnimating];
}

@end
