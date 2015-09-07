//
//  WLColorPicker.m
//  meWrap
//
//  Created by Ravenpod on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLColorPicker.h"

@interface WLColorPicker ()

@property (strong, nonatomic) UIColor *color;

@end

@implementation WLColorPicker

- (void)awakeFromNib {
    [super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        NSMutableArray *colors = [NSMutableArray array];
        for (float hue = 0.0; hue < 1.0; hue += 0.001) {
            UIColor *color = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
            [colors addObject:color];
        }
        return colors;
    }, ^(NSArray *colors) {
        CGFloat x = 0;
        CGFloat height = weakSelf.height;
        CGFloat width = weakSelf.width / (CGFloat)colors.count;
        for (UIColor *color in colors) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, width, height)];
            view.backgroundColor = color;
            [weakSelf addSubview:view];
            x += width;
        }
    });
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.color = touch.view.backgroundColor;
    [self.delegate colorPicker:self pickedColor:self.color];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    for (UIView *subview in self.subviews) {
        if (CGRectContainsPoint(subview.frame, [touch locationInView:self])) {
            UIColor *color = subview.backgroundColor;
            if (![self.color isEqual:color]) {
                [self.delegate colorPicker:self pickedColor:color];
            }
            break;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.color = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.color = nil;
}

@end
