//
//  WLCountriesViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLCountry;

@interface WLCountriesViewController : WLBaseViewController

@property (strong, nonatomic) WLCountry *selectedCountry;

@end
