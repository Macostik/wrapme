//
//  WLSizeToFitLabel.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
static CGFloat WLConstantPadding = 10.0f;

#import "WLBadgeLabel.h"
#import "NSString+Additions.h"
#import "UILabel+Additions.h"

@interface WLBadgeLabel ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation WLBadgeLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.hidden = YES;
    }
    return self;
}

- (void)sizeToFitByContent {
    CGFloat width = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, self.height)].width;
    width += width + WLConstantPadding > self.height ? WLConstantPadding : .0;
    self.widthConstraint.constant = Smoothstep(self.height, self.superview.width, width);
}

- (BOOL)isHiddenValueForText:(NSString*)text {
    return [text isEqualToString:@"0"] || ![text nonempty];;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.hidden = [self isHiddenValueForText:text];
    [self sizeToFitByContent];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    self.hidden = [self isHiddenValueForText:attributedText.string];
    [self sizeToFitByContent];
}

- (void)setIntValue:(NSUInteger)intValue {
    [self setText:[NSString stringWithFormat:@"%lu", (unsigned long)intValue]];
}

@end
