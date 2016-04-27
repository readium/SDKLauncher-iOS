//
//  Created by Mickaël Menu on 09/12/15.
//  Copyright © 2015 The Readium Foundation. All rights reserved.
//
//  The LCPService provided by the LCP library is independant from the Readium
//  SDK. This subclass serves as glue between Readium and LCP. Moreover, it adds
//  a convenient singleton object that will initialize the service with the
//  launcher's root certificate, located in Resources/LCP Root Certificate.crt
//

#import <Foundation/Foundation.h>

#import <lcp/apple/lcp.h>

//#import <lcp/LcpContentFilter.h>
//#import <lcp/LcpContentModule.h>

@class RDLcpCredentialHandler;

@interface RDLCPService : LCPService

+ (instancetype)sharedService;

// To be called by the RDContainerDelegate implementation
//- (void)registerContentFilter;
- (void)registerContentModule:(RDLcpCredentialHandler *) credentialHandler;
//- (void)registerContentModule:(lcp::ICredentialHandler *) credentialHandler;

@end
