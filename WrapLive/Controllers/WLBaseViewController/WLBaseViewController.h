//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLKeyboard.h"

@interface WLBaseViewController : UIViewController <WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *keyboardAdjustmentLayoutViews;

@property (nonatomic) BOOL keyboardAdjustmentAnimated;

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight;

@end
