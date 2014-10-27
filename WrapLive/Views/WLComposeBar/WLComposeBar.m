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

static NSUInteger WLComposeBarDefaultCharactersLimit = 360;
static NSUInteger WLComposeBarMaxHeight = 100;
static NSUInteger WLComposeBarMinHeight = 44;

@interface WLComposeBar () <UITextViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (strong, nonatomic) UIView *composeView;
@property (nonatomic) CGRect defaultSize;
@property (strong, nonatomic) WLEmojiView * emojiView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@end

@implementation WLComposeBar

- (void)awakeFromNib {
	[super awakeFromNib];
	self.composeView = [UIView loadFromNibNamed:@"WLComposeBar" ownedBy:self];
	self.composeView.frame = self.bounds;
	self.defaultSize = self.bounds;
    [self addSubview:self.composeView];
	self.textView.superview.layer.borderColor = [UIColor WL_grayColor].CGColor;
	self.textView.superview.layer.borderWidth = 0.5f;
	self.textView.textContainerInset = UIEdgeInsetsMake(5, 0, 6, 0);
	[self updateStateAnimated:NO];
}

- (void)checkHeight {
    CGFloat height = [self.textView sizeThatFits:CGSizeMake(self.textView.width, CGFLOAT_MAX)].height + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    height = Smoothstep(WLComposeBarMinHeight, WLComposeBarMaxHeight, height);
    if (ABS(height - self.height) > 5) {
        self.height = height;
        self.composeView.height = height;
        if ([self.delegate respondsToSelector:@selector(composeBarDidChangeHeight:)]) {
            [self.delegate composeBarDidChangeHeight:self];
        }
    }
}

- (void)setHeight:(CGFloat)height {
    if (self.heightConstraint) {
        self.heightConstraint.constant = height;
        [self.heightConstraint.firstItem layoutIfNeeded];
        [self.heightConstraint.secondItem layoutIfNeeded];
    } else {
        [super setHeight:height];
    }
}

- (NSString *)text {
	return self.textView.text;
}

- (void)setText:(NSString *)text {
	self.textView.text = text;
    [self checkHeight];
	[self updateStateAnimated:YES];
	if ([self.delegate respondsToSelector:@selector(composeBarDidChangeHeight:)]) {
		[self.delegate composeBarDidChangeHeight:self];
	}
}

- (void)updateStateAnimated:(BOOL)animated {
	[self setDoneButtonHidden:!self.textView.text.nonempty animated:animated];
}

- (NSString *)placeholder {
	return self.textView.placeholder;
}

- (void)setPlaceholder:(NSString *)placeHolder {
	self.textView.placeholder = placeHolder;
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
		[self.delegate composeBar:self didFinishWithText:self.textView.text];
	}
	self.text = nil;
    [self checkHeight];
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden {
	[self setDoneButtonHidden:doneButtonHidden animated:NO];
}

- (void)setDoneButtonHidden:(BOOL)hidden animated:(BOOL)animated {
	CGFloat x = hidden ? self.width : (self.width - self.doneButton.width);
	if (x != self.doneButton.x) {
		_doneButtonHidden = hidden;
		CGFloat width = (x - self.textView.superview.x - (hidden ? 10 : 0));
		if (animated) {
			[UIView beginAnimations:nil context:nil];
		}
		self.doneButton.x = x;
		self.textView.superview.width = width;
		if (animated) {
			[UIView commitAnimations];
		}
	}
}

- (WLEmojiView *)emojiView {
	__weak typeof(self)weakSelf = self;
	if (!_emojiView) {
		_emojiView = [[WLEmojiView alloc] initWithSelectionBlock:^(NSString *emoji) {
            [weakSelf.textView insertText:emoji];
		} returnBlock:^{
            [weakSelf.textView deleteBackward];
		} andSegmentSelectionBlock:^(NSInteger index) {
			if (self.segmentSelectedBlock) {
				self.segmentSelectedBlock(index);
			}
		}];
	}
	return _emojiView;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	self.height = self.defaultSize.size.height;
	self.composeView.height = self.defaultSize.size.height;
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
	if ([text isEqualToString:@"\n"]) {
		CGFloat sizeAdjustment = textView.font.lineHeight * [UIScreen mainScreen].scale;
		[UIView animateWithDuration:0.2 animations:^{
			[textView setContentOffset:CGPointMake(textView.contentOffset.x, textView.contentOffset.y + sizeAdjustment)];
		}];
	}
	
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

@implementation WLTextView


- (void)awakeFromNib {
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textDidChange)
												 name:UITextViewTextDidChangeNotification
											   object:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setText:(NSString *)text {
	[super setText:text];
	[self textDidChange];
}

- (void)textDidChange {
	UILabel* placeholderLabel = objc_getAssociatedObject(self, "placeholderLabel");
	placeholderLabel.hidden = self.text.length != 0;
}

- (void)setPlaceholder:(NSString *)placeHolder {
	UILabel* placeholderLabel = objc_getAssociatedObject(self, "placeholderLabel");
	if (!placeholderLabel) {
		placeholderLabel = [[UILabel alloc] init];
		placeholderLabel.backgroundColor = [UIColor clearColor];
		placeholderLabel.frame = CGRectMake(5, 0, 250, 30);
		placeholderLabel.font = [UIFont lightMicroFont];
		placeholderLabel.textColor = [UIColor WL_grayColor];
		placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:placeholderLabel];
		objc_setAssociatedObject(self, "placeholderLabel", placeholderLabel, OBJC_ASSOCIATION_ASSIGN);
	}
	
	placeholderLabel.text = placeHolder;
}

- (NSString *)placeholder {
	UILabel* placeholderLabel = objc_getAssociatedObject(self, "placeholderLabel");
	if (placeholderLabel) {
		return placeholderLabel.text;
	}
	return nil;
}

@end
