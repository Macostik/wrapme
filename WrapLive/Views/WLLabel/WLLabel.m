//
//  WLLabel.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLabel.h"

@implementation WLLabel

-(CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    CGRect rect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    UIViewContentMode contentMode = self.contentMode;
    switch (contentMode) {
        case UIViewContentModeTop:
            rect.origin = bounds.origin;
            break;
        case UIViewContentModeBottom:
            rect.origin.x = bounds.origin.x;
            rect.origin.y = bounds.origin.y + (bounds.size.height - rect.size.height);
            break;
        default:
            break;
    }
    return rect;
}

-(void)drawTextInRect:(CGRect)rect {
    CGRect r = [self textRectForBounds:rect
                limitedToNumberOfLines:self.numberOfLines];
    [super drawTextInRect:r];
}

@end
