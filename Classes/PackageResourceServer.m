//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceServer.h"
#import "HTTPServer.h"
#import "PackageResourceConnection.h"
#import "RDPackage.h"
#import "RDPackageResource.h"


static id m_resourceLock = nil;


@implementation PackageResourceServer


- (void)dealloc {
	[m_httpServer stop];
	[PackageResourceConnection setPackage:nil];
}


+ (void)initialize {
	m_resourceLock = [[NSObject alloc] init];
}


- (id)initWithPackage:(RDPackage *)package {
	if (package == nil) {
		return nil;
	}

	if (self = [super init]) {
		m_package = package;
		m_httpServer = [[HTTPServer alloc] init];

		if (m_httpServer == nil) {
			NSLog(@"The HTTP server is nil!");
			return nil;
		}

		m_httpServer.documentRoot = @"";
		[m_httpServer setConnectionClass:[PackageResourceConnection class]];

		NSError *error = nil;
		BOOL success = [m_httpServer start:&error];

		if (!success || error != nil) {
			if (error != nil) {
				NSLog(@"Could not start the HTTP server! %@", error);
			}

			return nil;
		}

		[PackageResourceConnection setPackage:package];
	}

	return self;
}


- (int)port {
	return m_httpServer.listeningPort;
}


+ (id)resourceLock {
	return m_resourceLock;
}


@end
