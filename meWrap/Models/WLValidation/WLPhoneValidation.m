//
//  WLPhoneValidation.m
//  meWrap
//
//  Created by Ravenpod on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPhoneValidation.h"
#import <libPhoneNumber_iOS/NBAsYouTypeFormatter.h>
#import "NSString+Additions.h"

@interface WLPhoneValidation ()

@property (strong, nonatomic) NBAsYouTypeFormatter *formatter;

@end

@implementation WLPhoneValidation

- (void)setCountry:(Country *)country {
    _country = country;
    self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:country.code];
    NSString* text = self.inputView.text;
    if (text.nonempty) {
        self.inputView.text = [self.formatter inputString:phoneNumberClearing(text)];
        [self validate];
    }
}

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView {
    WLValidationStatus status = [super defineCurrentStatus:inputView];
    if (status == WLValidationStatusValid) {
        status = inputView.text.length > 5 ? WLValidationStatusValid : WLValidationStatusInvalid;
    }
    return status;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length > 0) {
        textField.text = [self.formatter inputDigit:string];
    } else {
        textField.text = [self.formatter removeLastDigit];
    }
    return NO;
}

@end
