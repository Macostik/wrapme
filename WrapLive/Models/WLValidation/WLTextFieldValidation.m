//
//  WLTextFieldValidation.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTextFieldValidation.h"
#import "NSString+Additions.h"

@interface WLTextFieldValidation ()

@end

@implementation WLTextFieldValidation

@dynamic inputView;

- (void)setInputView:(UITextField *)inputView {
    [super setInputView:inputView];
    if ([inputView isKindOfClass:[UITextField class]]) {
        inputView.delegate = self;
        [inputView addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
}

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView {
    return inputView.text.nonempty ? WLValidationStatusValid : WLValidationStatusInvalid;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidChange:(UITextField*)textField {
    NSUInteger limit = self.limit;
    NSString* text = textField.text;
    if (limit > 0 && text.length > limit) {
        textField.text = [text substringToIndex:limit];
    }
    [self validate];
}

@end
