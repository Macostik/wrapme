//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLKeyboardBroadcaster.h"

@interface WLBaseViewController : UIViewController <WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *keyboardAdjustmentLayoutViews;

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight;

@end
