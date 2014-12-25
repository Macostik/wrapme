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

@property (weak, nonatomic, readonly) UIView *contentView;

@property (nonatomic) BOOL isEmbedded;

+ (BOOL)isEmbeddedDefaultValue;

- (void)embeddingViewTapped:(UITapGestureRecognizer*)sender;

- (void)addEmbeddingConstraintsToContentView:(UIView*)contentView inView:(UIView*)view;

- (void)awakeAfterInit;

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight;

- (void)setPlaceholderNib:(UINib*)nib forType:(NSUInteger)type;

- (void)setPlaceholderVisible:(BOOL)visible forType:(NSUInteger)type;

- (void)updatePlaceholderVisibilityForType:(NSUInteger)type;

- (BOOL)placeholderVisibleForType:(NSUInteger)type;

@end
