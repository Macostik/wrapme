//
//  WLTypingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTypingView.h"
#import "UIView+Shorthand.h"

static CGFloat WLMinBubbleWidth = 15.0f;
CGFloat WLMaxTextViewWidth;

@implementation WLTypingView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}

- (void)setName:(NSString *)name {
    self.nameTextField.text = name;
    __weak __typeof(self)weakSelf = self;
    [UIView performWithoutAnimation:^{
        CGSize size = [self.nameTextField sizeThatFits:CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX)];
        weakSelf.textViewConstraint.constant =  weakSelf.width - 3.0 -  MAX(WLMinBubbleWidth, size.width);;
        [self layoutIfNeeded];
    }];
}

@end
