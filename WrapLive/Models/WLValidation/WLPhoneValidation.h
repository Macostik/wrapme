//
//  WLPhoneValidation.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTextFieldValidation.h"

@class RMPhoneFormat;

@interface WLPhoneValidation : WLTextFieldValidation

@property (strong, nonatomic) RMPhoneFormat *format;

@end
