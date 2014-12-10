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

@property (nonatomic) BOOL viewAppeared;

@property (nonatomic) BOOL backSwipeGestureEnabled;

@property (nonatomic) BOOL showsPlaceholderView;

@property (weak, nonatomic) UIView *placeholderView;

@property (weak, nonatomic, readonly) UIView *contentView;

@property (nonatomic) BOOL isEmbedded;

+ (BOOL)isEmbeddedDefaultValue;

- (void)embeddingViewTapped:(UITapGestureRecognizer*)sender;

- (void)awakeAfterInit;

- (UINib*)placeholderViewNib;

- (void)showPlaceholderView;

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight;

@end
