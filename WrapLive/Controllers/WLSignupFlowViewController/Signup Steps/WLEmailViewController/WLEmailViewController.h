//
//  WLEmailViewController.h
//  moji
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupStepViewController.h"

typedef NS_ENUM(NSUInteger, WLEmailStepStatus) {
    WLEmailStepStatusVerification,
    WLEmailStepStatusLinkDevice,
    WLEmailStepStatusUnconfirmedEmail
};

@interface WLEmailViewController : WLSignupStepViewController

@end
