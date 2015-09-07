//
//  WLTelephony.m
//  meWrap
//
//  Created by Ravenpod on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTelephony.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "NSString+Additions.h"
#import <MessageUI/MessageUI.h>

@implementation WLTelephony

+ (NSString*)countryCode {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    return [[[networkInfo subscriberCellularProvider] isoCountryCode] lowercaseString];
}

+ (BOOL)isCallingNow {
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall* call in callCenter.currentCalls) {
        if ([call.callState matches:CTCallStateConnected, CTCallStateIncoming, nil]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)hasPhoneNumber {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    return [MFMessageComposeViewController canSendText] && [networkInfo subscriberCellularProvider].mobileCountryCode.nonempty;
}

@end
