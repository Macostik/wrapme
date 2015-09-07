//
//  UITextView+Aditions.m
//  meWrap
//
//  Created by Yura Granchenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
#import "UITextView+Aditions.h"

@implementation UITextView (Aditions)

- (void)determineHyperLink:(NSString *)string {
    if (string) {
        self.attributedText = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : self.font,
                                                                                             NSForegroundColorAttributeName : self.textColor ? : [UIColor blackColor]}];
    } else {
        self.text = nil;
    }
}

@end
