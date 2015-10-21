//
//  WLCountriesViewController.h
//  meWrap
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLCountriesViewController : WLBaseViewController

@property (strong, nonatomic) Country *selectedCountry;

@property (strong, nonatomic) void (^selectionBlock) (Country *country);

@end
