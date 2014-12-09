//
//  WLValidationGroup.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLValidationGroup.h"

@interface WLValidationGroup () <WLValidationDelegate>

@end

@implementation WLValidationGroup

- (void)setValidations:(NSArray *)validations {
    _validations = validations;
    [validations makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
}

- (WLValidationStatus)defineCurrentStatus:(UIView *)inputView {
    for (WLValidation* validation in self.validations) {
        if (validation.status != WLValidationStatusValid) {
            self.reason = validation.reason;
            return validation.status;
        }
    }
    return WLValidationStatusValid;
}

#pragma mark - WLValidationDelegate

- (void)validationStatusChanged:(WLValidation *)validation {
    [self validate];
}

@end
