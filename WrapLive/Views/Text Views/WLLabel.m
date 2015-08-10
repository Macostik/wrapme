//
//  WLLabel.m
//  moji
//
//  Created by Ravenpod on 11/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLabel.h"
#import "WLFontPresetter.h"
#import "UIFont+CustomFonts.h"

@implementation WLLabel

#if !TARGET_INTERFACE_BUILDER
- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    CGRect rect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    UIViewContentMode contentMode = self.contentMode;
    switch (contentMode) {
        case UIViewContentModeTop:
            rect.origin.y = 0;
            break;
        case UIViewContentModeBottom:
            rect.origin.y = bounds.size.height - rect.size.height;
            break;
        default:
            break;
    }
    return rect;
}

- (void)drawTextInRect:(CGRect)rect {
    UIViewContentMode contentMode = self.contentMode;
    if (contentMode == UIViewContentModeTop || contentMode == UIViewContentModeBottom) {
        [super drawTextInRect:[self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines]];
    } else {
        [super drawTextInRect:rect];
    }
}
#endif

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.font = [self.font preferredFontWithPreset:preset];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.font = [self.font preferredFontWithPreset:self.preset];
}

@end
