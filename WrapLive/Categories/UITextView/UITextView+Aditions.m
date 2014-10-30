//
//  UITextView+Aditions.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
#import "UITextView+Aditions.h"

@implementation UITextView (Aditions)

- (void)determineHyperLink:(NSString *)string {
    if (string) {
        NSMutableAttributedString *attrebutedText = [[NSMutableAttributedString alloc] initWithString:string];
        NSDictionary * attributes = @{NSFontAttributeName : self.font};
        [attrebutedText addAttributes:attributes range:NSMakeRange(0, [attrebutedText length])];
        self.attributedText = attrebutedText;
    } else {
        self.text = nil;
    }
}

@end
