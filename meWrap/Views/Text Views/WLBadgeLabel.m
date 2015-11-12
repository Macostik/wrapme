//
//  WLSizeToFitLabel.m
//  meWrap
//
//  Created by Yura Granchenko on 9/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
#import "WLBadgeLabel.h"

@interface WLBadgeLabel ()

@end

@implementation WLBadgeLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.intValue = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.intValue = 0;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.intValue = 0;
    }
    return self;
}

- (BOOL)isHiddenValueForText:(NSString*)text {
    return [text isEqualToString:@"0"] || ![text nonempty];;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.hidden = [self isHiddenValueForText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    self.hidden = [self isHiddenValueForText:attributedText.string];
}

- (void)setIntValue:(NSUInteger)intValue {
    [self setText:[NSString stringWithFormat:@"%lu", (unsigned long)intValue]];
}

- (CGSize)intrinsicContentSize {
    CGSize insets = self.intrinsicContentSizeInsets;
    CGSize size = [super intrinsicContentSize];
    size = CGSizeMake(size.width + insets.width, size.height + insets.height);
    self.layer.cornerRadius = size.height/2;
    return size;
}

@end
