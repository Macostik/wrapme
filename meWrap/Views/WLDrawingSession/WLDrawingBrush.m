//
//  WLDrawingBrush.m
//  meWrap
//
//  Created by Ravenpod on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingBrush.h"

@implementation WLDrawingBrush

+ (instancetype)brushWithColor:(UIColor *)color width:(CGFloat)width {
    WLDrawingBrush *brush = [[[self class] alloc] init];
    brush.width = width;
    brush.color = color;
    return brush;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.opacity = 1;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WLDrawingBrush *brush = [[[self class] allocWithZone:zone] init];
    brush.width = self.width;
    brush.color = self.color;
    return brush;
}

- (BOOL)isEqualToBrush:(WLDrawingBrush *)brush {
    return [self.color isEqual:brush.color] && self.width == brush.width && self.opacity == brush.opacity;
}

@end
