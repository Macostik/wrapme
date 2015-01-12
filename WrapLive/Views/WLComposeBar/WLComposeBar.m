//
//  WLComposeBar.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLComposeBar.h"
#import "NSObject+NibAdditions.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import <objc/runtime.h>
#import "NSString+Additions.h"
#import "WLEmojiView.h"
#import "WLEmoji.h"
#import "UIView+AnimationHelper.h"
#import "GeometryHelper.h"
#import "UIFont+CustomFonts.h"

static CGFloat WLComposeBarDefaultCharactersLimit = 360.0f;
static CGFloat WLComposeBarMinHeight = 44.0f;

@interface WLComposeBar () <UITextViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) UIView *composeView;
@property (nonatomic) CGFloat defaultHeight;
@property (strong, nonatomic) WLEmojiView * emojiView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalSpaceDoneButtonContstraint;

@end

@implementation WLComposeBar

- (void)awakeFromNib {
	[super awakeFromNib];
	self.composeView = [UIView loadFromNibNamed:@"WLComposeBar" ownedBy:self];
	self.composeView.frame = self.bounds;
	self.defaultHeight = self.bounds.size.height;
    [self addSubview:self.composeView];
	self.textView.superview.layer.borderColor = [UIColor colorWithHexString:@"#EEEEEE"].CGColor;
    self.textView.superview.layer.borderWidth = WLConstants.pixelSize;
	self.textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.textView.contentInset = UIEdgeInsetsZero;
	[self updateStateAnimated:NO];
}

- (void)checkHeight {
    CGFloat height = WLComposeBarMinHeight;
    UITextView* textView = self.textView;
    if (textView.text.nonempty) {
        height = [textView sizeThatFits:CGSizeMake(textView.width, CGFLOAT_MAX)].height;
        self.height =  Smoothstep(textView.font.lineHeight, textView.font.lineHeight * 2, height) + textView.superview.y*2 + textView.y*2;
        if (textView.selectedRange.location == textView.text.length) {
            CGPoint bottomOffset = CGPointMake(0, textView.contentSize.height - textView.height);
            [textView setContentOffset:bottomOffset animated:YES];
        }
    } else {
        self.height = height;
    }
    if ([self.delegate respondsToSelector:@selector(composeBarDidChangeHeight:)]) {
        [self.delegate composeBarDidChangeHeight:self];
    }
}

- (void)setHeight:(CGFloat)height {
    NSLayoutConstraint* constraint = self.heightConstraint;
    if (constraint) {
        constraint.constant = height;
        [constraint.firstItem layoutIfNeeded];
        [constraint.secondItem layoutIfNeeded];
    } else {
        [super setHeight:height];
    }
}

- (NSString *)text {
	return self.textView.text;
}

- (void)setText:(NSString *)text {
	self.textView.text = text;
    self.placeholderLabel.hidden = text.nonempty;
    [self checkHeight];
    [self updateStateAnimated:YES];
}

- (void)updateStateAnimated:(BOOL)animated {
	[self setDoneButtonHidden:!self.textView.text.nonempty animated:animated];
}

- (NSString *)placeholder {
	return self.placeholderLabel.text;
}

- (void)setPlaceholder:(NSString *)placeHolder {
	self.placeholderLabel.text = placeHolder;
}

- (void)finish {
	BOOL shouldResign = YES;
	if ([self.delegate respondsToSelector:@selector(composeBarDidShouldResignOnFinish:)]) {
		shouldResign = [self.delegate composeBarDidShouldResignOnFinish:self];
	}
	if (shouldResign) {
		[self.textView resignFirstResponder];
	}
	NSString* text = [self.text trim];
	if (text.nonempty) {
		[self.delegate composeBar:self didFinishWithText:text];
	}
	self.text = nil;
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden {
	[self setDoneButtonHidden:doneButtonHidden animated:NO];
}

- (void)setDoneButtonHidden:(BOOL)hidden animated:(BOOL)animated {
    self.doneButton.userInteractionEnabled = !hidden;
    self.doneButton.hidden = hidden;
    [UIView performAnimated:animated animation:^{
        self.horizontalSpaceDoneButtonContstraint.constant = hidden ? -self.doneButton.width : 0;
        [self.textView.superview layoutIfNeeded];
    }];
}

- (WLEmojiView *)emojiView {
	if (!_emojiView) {
		_emojiView = [[WLEmojiView alloc] initWithTextView:self.textView];
	}
	return _emojiView;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self finish];
}

- (IBAction)selectEmoji:(UIButton *)sender {
	sender.selected = !sender.selected;
	self.textView.inputView = nil;
	if (sender.selected) {
		self.textView.inputView = self.emojiView;
	}
	if (![self isFirstResponder]) {
		[self becomeFirstResponder];
	}
	[self.textView reloadInputViews];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(composeBarDidChangeText:)]) {
        [self.delegate composeBarDidChangeText:self];
    }
    self.placeholderLabel.hidden = textView.text.nonempty;
    [self checkHeight];
	[self updateStateAnimated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	if ([self.delegate respondsToSelector:@selector(composeBarDidBeginEditing:)]) {
		[self.delegate composeBarDidBeginEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if ([self.delegate respondsToSelector:@selector(composeBarDidEndEditing:)]) {
		[self.delegate composeBarDidEndEditing:self];
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSUInteger charactersLimit;
	if ([self.delegate respondsToSelector:@selector(composeBarCharactersLimit:)] && self.height > 44) {
		charactersLimit = [self.delegate composeBarCharactersLimit:self];
	} else {
		charactersLimit = WLComposeBarDefaultCharactersLimit;
	}
	NSString* resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
	return resultString.length <= charactersLimit;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
	return [self.textView canBecomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
	return [self.textView canResignFirstResponder];
}

- (BOOL)isFirstResponder {
	return [self.textView isFirstResponder];
}

- (BOOL)becomeFirstResponder {
	return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [self.textView resignFirstResponder];
}

@end
