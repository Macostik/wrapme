//
//  WLCountriesViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSignupStepViewController.h"

@class WLCountry;

@interface WLCountriesViewController : WLSignupStepViewController

@property (strong, nonatomic) WLCountry *selectedCountry;

@end
