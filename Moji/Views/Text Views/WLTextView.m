//
//  WLTextView.m
//  moji
//
//  Created by Ravenpod on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTextView.h"
#import "UIColor+CustomColors.h"
#import "WLFontPresetter.h"
#import "UIFont+CustomFonts.h"

@interface WLTextView ()

@property (weak, nonatomic) IBOutlet UILabel* placeholderLabel;

@end

@implementation WLTextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    if (!self.editable && self.dataDetectorTypes != UIDataDetectorTypeNone) {
        self.dataDetectorTypes = UIDataDetectorTypeAll;
    }
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    self.placeholderLabel.hidden = hidden;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textDidChange];
}

- (void)textDidChange {
    self.placeholderLabel.hidden = self.text.length != 0;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        UILabel* placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.backgroundColor = [UIColor clearColor];
        placeholderLabel.frame = CGRectMake(5, 0, 250, 30);
        placeholderLabel.font = self.font;
        placeholderLabel.textColor = [UIColor WL_grayLight];
        placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:placeholderLabel];
        _placeholderLabel = placeholderLabel;
    }
    return _placeholderLabel;
}

- (void)setPlaceholder:(NSString *)placeHolder {
    self.placeholderLabel.text = placeHolder;
}

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.font = [self.font preferredFontWithPreset:preset];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.font = [self.font preferredFontWithPreset:self.preset];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if  (self.editable || self.dataDetectorTypes == UIDataDetectorTypeNone) return [super pointInside:point withEvent:event];
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:self.dataDetectorTypes
                                                               error:nil];
    NSArray* resultString = [detector matchesInString:self.text
                                              options:NSMatchingReportProgress
                                                range:NSMakeRange(0, [self.text length])];
    for (NSTextCheckingResult *result in resultString) {
        NSRange range = result.range;
        __block BOOL insideFlag = NO;
        [self.layoutManager enumerateEnclosingRectsForGlyphRange:range
                                        withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                                                 inTextContainer:self.textContainer
                                                      usingBlock:^(CGRect rect, BOOL *stop) {
                                                          insideFlag = CGRectContainsPoint(rect, point);
                                                          if (insideFlag) {
                                                              *stop = YES;
                                                          }
                                                      }];
        return insideFlag;
    }
    return NO;
}

@end
