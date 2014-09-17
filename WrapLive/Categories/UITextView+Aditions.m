//
//  UITextView+Aditions.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"

@implementation UITextView (Aditions)

- (void)determineHyperLink:(NSString *)string {
    self.editable = NO;
    self.dataDetectorTypes = UIDataDetectorTypeLink;
    NSMutableAttributedString *attrebutedText = [[NSMutableAttributedString alloc] initWithString:string];
    NSDictionary * attributes = @{NSFontAttributeName : [UIFont lightFontOfSize:15.0f]};
    [attrebutedText addAttributes:attributes range:NSMakeRange(0, [attrebutedText length])];
    self.attributedText = attrebutedText;
}

@end
