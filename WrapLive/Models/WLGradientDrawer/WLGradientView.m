//
//  WLGradientView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLGradientView.h"
#import "WLGradientDrawer.h"

@interface WLGradientView ()

@property (nonatomic) UIViewContentMode drawContentMode;

@end

@implementation WLGradientView

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:UIViewContentModeScaleToFill];
    self.drawContentMode = contentMode;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self redrawGradient];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self redrawGradient];
}

- (void)redrawGradient {
    if (self.color) {
        self.image = [WLGradientDrawer imageWithSize:self.bounds.size.height color:self.color mode:self.drawContentMode];
    }
}

@end
