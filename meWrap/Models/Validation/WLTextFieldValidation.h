//
//  WLTextFieldValidation.h
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class ValidationStatus;

@interface WLTextFieldValidation : Validation <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField* inputView;

@property (nonatomic) NSUInteger limit;

- (ValidationStatus)defineCurrentStatus:(UITextField *)inputView;

@end
