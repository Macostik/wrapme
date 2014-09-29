//
//  WLSizeToFitLabel.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
static CGFloat WLConstantWidth = 22.0f;
static CGFloat WLConstantPadding = 12.0f;
static CGFloat WLConstantIndentText = 5.0f;

#import "WLSizeToFitLabel.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"
#import "UILabel+Additions.h"

@implementation WLSizeToFitLabel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.hidden = YES;
        self.verticalAlignment = VerticalAlignmentMiddle;
    }
    return self;
}

- (void)sizeToFitByContent {
    int width = MAX(WLConstantWidth, [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, WLConstantWidth)].width + WLConstantPadding);
    self.width = MIN(width, self.superview.width);
    if (self.contentMode == UIViewContentModeRight) {
        self.x -=  self.width <= WLConstantWidth ? : self.width - WLConstantWidth;
   }
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.hidden = [text isEqualToString:@"0"] || ![text nonempty];
    [self sizeToFitByContent];
    [self setNeedsDisplay];
}

- (void)setIntValue:(NSInteger)intValue {
    [self setText:[NSString stringWithFormat:@"%d", (int)intValue]];
}

- (void)drawTextInRect:(CGRect)rect {
    CGRect frame;
    switch (self.verticalAlignment)
    {
        case VerticalAlignmentTop:
            frame = (CGRect){{rect.origin.x, rect.origin.y - WLConstantIndentText},{self.width, self.height}};
            break;
        case VerticalAlignmentMiddle:
            frame  = (CGRect){{rect.origin.x,  rect.origin.y},{self.width, self.height}};
            break;
        case VerticalAlignmentBottom:
            frame  = (CGRect){{rect.origin.x,  rect.origin.y + WLConstantIndentText},{self.width, self.height}};
            break;
        default:
            frame = rect;
            break;
    }
    if (!CGRectIsEmpty(frame)) {
        [super drawTextInRect:frame];
    }
}

@end
