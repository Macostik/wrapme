//
//  WLTermsAndConditionsKeys.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

static NSString* WLTermsAndCoditionsKey = @"Terms and Conditions";
static NSString* WLCollectionOfInformationKey = @"Collection of Information You Provide to Us";
static NSString* WLInformationKey = @"Information Storage and Processing";
static NSString* WLInappropriateKey = @"Inappropriate Content";
static NSString* WLSharingKey = @"Sharing Your Content and Information";
static NSString* WLUseOfInformationKey = @"Use of Information";
static NSString* WLSecurityKey = @"Security";
static NSString* WLChildrenUnderThirteenKey = @"Children Under Thirteen";
static NSString* WLAccountInformationKey = @"Account Information";
static NSString* WLDeviceInformationKey = @"Device Information";
static NSString* WLLocationKey = @"Location";
static NSString* WLCookiesKey = @"Cookies";
static NSString* WLPushNotificationsAndAlertsKey = @"Push Notifications/Alerts";
static NSString* WLContactKey = @"Contact";

static inline NSArray *titleKeyArray() {
    return [NSArray arrayWithObjects:WLTermsAndCoditionsKey, WLCollectionOfInformationKey, WLInformationKey,
                                     WLInappropriateKey, WLSharingKey, WLUseOfInformationKey, WLSecurityKey,
                                     WLChildrenUnderThirteenKey, WLAccountInformationKey, WLDeviceInformationKey,
                                     WLLocationKey, WLCookiesKey, WLPushNotificationsAndAlertsKey, WLContactKey, nil];
}