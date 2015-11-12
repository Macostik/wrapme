//
//  WLEmailValidation.m
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailValidation.h"

@implementation WLEmailValidation

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView {
    WLValidationStatus status = [super defineCurrentStatus:inputView];
    if (status == WLValidationStatusValid) {
        status = [inputView.text isValidEmail] ? WLValidationStatusValid : WLValidationStatusInvalid;
    }
    return status;
}

@end
