//
//  WLEmailViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupStepViewController.h"

typedef NS_ENUM(NSUInteger, WLEmailViewControllerCompletionStatus) {
    WLEmailViewControllerCompletionStatusVerification,
    WLEmailViewControllerCompletionStatusLinkDevice,
    WLEmailViewControllerCompletionStatusUnconfirmedEmail
};

@interface WLEmailViewController : WLSignupStepViewController

@end
