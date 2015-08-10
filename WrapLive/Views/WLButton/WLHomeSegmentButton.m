//
//  WLHomeSegmentButton.m
//  moji
//
//  Created by Ravenpod on 8/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHomeSegmentButton.h"
#import "UIColor+CustomColors.h"

@implementation WLHomeSegmentButton

- (void)setHighlighted:(BOOL)highlighted {
    
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.selected) {
        UIColor *color = [self.backgroundColor self];
        CGFloat locations[4] = {0,0.2,0.8,1};
        NSArray *colors = @[(id)[color colorByAddingValue:-0.1].CGColor,(id)color.CGColor,(id)color.CGColor,(id)[color colorByAddingValue:-0.1].CGColor];
        CGGradientRef gr = CGGradientCreateWithColors(NULL, ((__bridge CFArrayRef)colors), locations);
        CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gr, CGPointMake(0, rect.size.height/2), CGPointMake(rect.size.width, rect.size.height/2), 0);
        CGGradientRelease(gr);
    }
}
@end
