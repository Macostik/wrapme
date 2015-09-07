//
//  WLTextFieldValidation.h
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLValidation.h"

@interface WLTextFieldValidation : WLValidation <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField* inputView;

@property (nonatomic) NSUInteger limit;

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView;

@end
