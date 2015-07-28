//
//  PGFocusAnimationView.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 7/10/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLCameraAdjustmentView.h"
#import "UIColor+CustomColors.h"
#import "UIFont+CustomFonts.h"

@interface WLCameraAdjustmentView ()

@end

@implementation WLCameraAdjustmentView

- (void)setType:(WLCameraAdjustmentType)type {
    _type = type;
    
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, 5.0f, 5.0f)];
    path.lineWidth = 1.0f;
    
    UIColor* color = nil;
    
    if (_type == WLCameraAdjustmentTypeCombined) {
        color = [[UIColor WL_orange] colorWithAlphaComponent:0.5f];
    } else if (_type == WLCameraAdjustmentTypeFocus) {
        color = [[UIColor greenColor] colorWithAlphaComponent:0.5f];
    } else {
        color = [[UIColor yellowColor] colorWithAlphaComponent:0.5f];
    }
    [color set];
    
    [path stroke];
    
    NSString* text = nil;
    
    if (_type == WLCameraAdjustmentTypeExposure) {
        text = @"Exposure";
    } else if (_type == WLCameraAdjustmentTypeFocus) {
        text = @"Focus";
    }
    
    if (text) {
        NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        UIFont* font = [UIFont fontWithName:WLDefaultBoldSystemFont preset:WLFontPresetXSmall];
        NSDictionary* attributes = @{NSFontAttributeName:font,NSForegroundColorAttributeName:color, NSParagraphStyleAttributeName:paragraphStyle};
        NSAttributedString* string = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        
        CGRect textRect;
		textRect.origin = CGPointZero;
        textRect.size = string.size;
        
        [string drawInRect:CGRectCenteredInSize(textRect, self.bounds.size)];
    }
}

@end
