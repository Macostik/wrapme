//
//  WLTouchView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTouchView.h"
#import "UIView+QuatzCoreAnimations.h"

@implementation WLTouchView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(touchViewDidReceiveTouch:)]) {
        [self.delegate touchViewDidReceiveTouch:self];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSSet *exclusionRects = nil;
    if ([self.delegate respondsToSelector:@selector(touchViewExclusionRects:)]) {
        exclusionRects = [self.delegate touchViewExclusionRects:self];
    }
    for (NSValue* rectValue in exclusionRects) {
        if (CGRectContainsPoint([rectValue CGRectValue], point)) {
            return NO;
        }
    }
    return YES;
}

@end
