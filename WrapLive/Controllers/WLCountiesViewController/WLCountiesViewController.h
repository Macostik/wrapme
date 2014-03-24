//
//  WLCountiesViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLCountry;

@interface WLCountiesViewController : UIViewController

+ (void)show:(void (^) (WLCountry* country))completion;

- (void)show:(void (^) (WLCountry* country))completion;

@end
