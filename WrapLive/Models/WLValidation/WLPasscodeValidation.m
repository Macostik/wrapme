//
//  WLPasscodeValidation.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPasscodeValidation.h"

@implementation WLPasscodeValidation

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView {
    WLValidationStatus status = [super defineCurrentStatus:inputView];
    if (status == WLValidationStatusValid) {
        status = inputView.text.length == self.limit ? WLValidationStatusValid : WLValidationStatusInvalid;
    }
    return status;
}

@end
