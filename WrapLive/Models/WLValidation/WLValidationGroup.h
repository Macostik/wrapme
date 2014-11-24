//
//  WLValidationGroup.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLValidation.h"

@interface WLValidationGroup : WLValidation

@property (strong, nonatomic) IBOutletCollection(WLValidation) NSArray *validations;

@end
