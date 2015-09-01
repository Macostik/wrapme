//
//  WLCountriesViewController.h
//  moji
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLCountry;

@interface WLCountriesViewController : WLBaseViewController

@property (strong, nonatomic) WLCountry *selectedCountry;

@end
