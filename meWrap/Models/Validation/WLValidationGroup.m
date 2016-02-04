//
//  WLValidationGroup.m
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLValidationGroup.h"

@interface WLValidationGroup () <ValidationDelegate>

@end

@implementation WLValidationGroup

- (void)setValidations:(NSArray *)validations {
    _validations = validations;
    [validations makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
}

- (ValidationStatus)defineCurrentStatus:(UIView *)inputView {
    for (Validation* validation in self.validations) {
        if (validation.status != WLValidationStatusValid) {
            self.reason = validation.reason;
            return validation.status;
        }
    }
    return WLValidationStatusValid;
}

#pragma mark - WLValidationDelegate

- (void)validationStatusChanged:(Validation *)validation {
    [self validate];
}

@end
