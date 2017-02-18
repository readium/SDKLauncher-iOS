// Licensed to the Readium Foundation under one or more contributor license agreements.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
// 3. Neither the name of the organization nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LCPStatusDocumentProcessing_DeviceIdManager.h"

using namespace lcp;

@interface LCPStatusDocumentProcessing_DeviceIdManager ()


@end

@implementation LCPStatusDocumentProcessing_DeviceIdManager {
@private
    NSString* m_deviceName;
}

NSString* PREF_KEY_DEVICE_ID = @"READIUM_LCP_LSD_DEVICE_ID";
NSString* PREF_KEY_DEVICE_ID_CHECK = @"READIUM_LCP_LSD_DEVICE_ID_CHECK_";

- (instancetype)init_:(NSString*)deviceName
{
    self = [super init];
    if (self) {
        m_deviceName = deviceName;
    }
    
    return self;
}

- (NSString*)getDeviceNAME {
    return m_deviceName;
}

- (NSString*)getDeviceID {
    
    @try
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        
        NSString* uuid = [ud objectForKey:PREF_KEY_DEVICE_ID];
        if (uuid == nil) {
            
            CFUUIDRef uid = CFUUIDCreate(NULL);
            uuid = CFBridgingRelease(CFUUIDCreateString(NULL, uid));
            CFRelease(uid);
            
            [ud setObject:uuid forKey:PREF_KEY_DEVICE_ID];
            [ud synchronize];
        }
        
        return uuid;
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
        return @"UID";
    }
}

- (NSString*)checkDeviceID:(NSString*)key {
    
    @try
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        
        NSString* prefKey = [NSString stringWithFormat:@"%@%@", PREF_KEY_DEVICE_ID_CHECK, key];
        NSString* uuid = [ud objectForKey:prefKey];
        
        return uuid;
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
        return nil;
    }
}

- (void)recordDeviceID:(NSString*)key {
    
    @try
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        
        NSString* prefKey = [NSString stringWithFormat:@"%@%@", PREF_KEY_DEVICE_ID_CHECK, key];
        
        NSString* uuid = [self getDeviceID];
        
        [ud setObject:uuid forKey:prefKey];
        [ud synchronize];
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
    }
}

@end
