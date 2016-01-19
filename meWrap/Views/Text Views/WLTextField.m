//
//  WLTextField.m
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTextField.h"

@implementation WLTextField

#if !TARGET_INTERFACE_BUILDER
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (!self.disableSeparator) {
        UIBezierPath* path = [UIBezierPath bezierPath];
        CGFloat lineWidth = 1.0f/[UIScreen mainScreen].scale;
        path.lineWidth = lineWidth;
        CGFloat y = self.bounds.size.height - path.lineWidth/2.0f;
        [[path move:0 :y] line:self.bounds.size.width :y];
        UIColor *placeholderColor = nil;
    	if (self.strokeColor == nil) {
        	placeholderColor = [self.attributedPlaceholder attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
   		} else {
       	 placeholderColor = self.strokeColor;
   		}
        [placeholderColor setStroke];
        [path stroke];
    }
}
#endif

- (BOOL)resignFirstResponder{
    if (self.trim) {
        self.text = [self.text trim];
    }
    return [super resignFirstResponder];
}

- (void)setText:(NSString *)text {
    [super setText:text];  
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)setLocalize:(BOOL)localize {
    _localize = localize;
    if (localize) {
        NSString *text = self.placeholder;
        if (text.nonempty) {
            [super setPlaceholder:text.ls];
        }
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    if (self.localize) {
        [super setPlaceholder:placeholder.ls];
    } else {
        [super setPlaceholder:placeholder];
    }
}

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.font = [self.font fontWithPreset:preset];
    [[FontPresetter defaultPresetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(FontPresetter *)presetter {
    self.font = [self.font fontWithPreset:self.preset];
}

@end
