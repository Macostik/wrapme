//
//  WLBaseViewController.h
//  meWrap
//
//  Created by Ravenpod on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@protocol KeyboardNotifying;

@interface WLBaseViewController : GAITrackedViewController

@property (nonatomic) CGRect preferredViewFrame;

@property (weak, nonatomic) IBOutlet UIView* navigationBar;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray * __nullable keyboardAdjustmentLayoutViews;

@property (nonatomic) BOOL keyboardAdjustmentAnimated;

@property (nonatomic) BOOL viewAppeared;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray * __nullable keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray * __nullable keyboardAdjustmentTopConstraints;

@property (strong, nonatomic) NSMapTable* __nullable keyboardAdjustmentDefaultConstants;

+ (NSString* __nullable)lastAppearedScreenName;

- (BOOL)shouldUsePreferredViewFrame;

@end
