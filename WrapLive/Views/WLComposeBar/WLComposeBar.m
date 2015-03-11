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
#import "UIScrollView+Additions.h"

static CGFloat WLComposeBarDefaultCharactersLimit = NSIntegerMax;

@interface WLComposeBar () <UITextViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) WLEmojiView * emojiView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalSpaceDoneButtonContstraint;
@property (assign, nonatomic) IBInspectable CGFloat maxLines;
@property (assign, nonatomic) IBInspectable UIColor *borderColor;

@end

@implementation WLComposeBar

- (void)awakeFromNib {
	[super awakeFromNib];
    
	self.textView.superview.layer.borderColor = self.borderColor.CGColor;
    self.textView.superview.layer.borderWidth = WLConstants.pixelSize;
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    self.textView.textContainerInset = self.textView.contentInset = UIEdgeInsetsZero;
	[self updateStateAnimated:NO];
}

- (void)updateHeight {
    UITextView *textView = self.textView;
    CGFloat lineHeight = floorf(textView.font.lineHeight);
    CGFloat spacing = textView.y * 2;
    CGFloat height = [textView sizeThatFits:CGSizeMake(textView.width, CGFLOAT_MAX)].height + spacing;
    NSInteger maxLines = self.maxLines > 0 ? self.maxLines : 2;
    height = Smoothstep(36, maxLines*lineHeight + spacing, height);
    if (self.heightConstraint.constant != height) {
        self.heightConstraint.constant = height;
        [self layoutIfNeeded];
        if ([self.delegate respondsToSelector:@selector(composeBarDidChangeHeight:)]) {
            [self.delegate composeBarDidChangeHeight:self];
        }
    }
}

- (NSString *)text {
	return self.textView.text;
}

- (void)setText:(NSString *)text {
	self.textView.text = text;
    self.placeholderLabel.hidden = text.nonempty;
    [self updateHeight];
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
    [UIView performAnimated:animated animation:^{
        self.horizontalSpaceDoneButtonContstraint.constant = hidden ? 0 : -self.doneButton.width;
        [self layoutIfNeeded];
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
    [self updateHeight];
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

- (void)textViewDidChangeSelection:(UITextView *)textView {
    [textView scrollRangeToVisible:textView.selectedRange];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGFloat maxOffsetY = scrollView.maximumContentOffset.y;
    if (offset.y > maxOffsetY) {
        offset.y = maxOffsetY;
        scrollView.contentOffset = offset;
    }
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
