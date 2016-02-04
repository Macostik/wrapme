//
//  WLValidationGroup.h
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@interface WLValidationGroup : Validation

@property (strong, nonatomic) IBOutletCollection(Validation) NSArray *validations;

@end
