//
//  WLTextView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/17/14.
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

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    self.placeholderLabel.hidden = hidden;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (BOOL)canBecomeFirstResponder {
    return self.editable;
}

@end
