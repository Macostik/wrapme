//
//  WLComposeBar.m
//  meWrap
//
//  Created by Ravenpod on 31.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLComposeBar.h"

@interface WLComposeBar () <UITextViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) EmojiView * emojiView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;
@property (assign, nonatomic) IBInspectable CGFloat maxLines;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *trailingPrioritizer;

@end

@implementation WLComposeBar

- (void)dealloc {
    self.textView.delegate = nil;
}

- (void)awakeFromNib {
	[super awakeFromNib];
    
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = self.textView.contentInset = UIEdgeInsetsZero;
	[self setDoneButtonHidden:YES];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)]];
    [self.textView.superview addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)]];
}

- (void)updateHeight {
    UITextView *textView = self.textView;
    CGFloat lineHeight = floorf(textView.font.lineHeight);
    CGFloat spacing = textView.y * 2;
    CGFloat height = [textView sizeThatFits:CGSizeMake(textView.width, CGFLOAT_MAX)].height + spacing;
    NSInteger maxLines = self.maxLines > 0 ? self.maxLines : 5;
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
    self.placeholderLabel.hidden = text.nonempty || self.textView.selectedRange.location != 0;
    [self updateHeight];
    [self setDoneButtonHidden:!text.nonempty];
}

- (void)setDoneButtonHidden:(BOOL)hidden {
    self.trailingPrioritizer.defaultState = hidden;
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
        if ([self.delegate respondsToSelector:@selector(composeBar:didFinishWithText:)]) {
            [self.delegate composeBar:self didFinishWithText:text];
        }
    }
    [[DispatchQueue mainQueue] runAfterAsap:^{
        self.text = nil;
    }];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subview in self.subviews) {
        BOOL inside = [subview pointInside:[subview convertPoint:point fromView:self] withEvent:event];
        if (inside) {
            return YES;
        }
    }
    return NO;
}

- (EmojiView *)emojiView {
	if (!_emojiView) {
		_emojiView = [EmojiView emojiViewWithTextView:self.textView];
        _emojiView.backgroundColor = self.backgroundColor;
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
    [self setDoneButtonHidden:!textView.text.nonempty];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self setDoneButtonHidden:!textView.text.nonempty];
	if ([self.delegate respondsToSelector:@selector(composeBarDidBeginEditing:)]) {
		[self.delegate composeBarDidBeginEditing:self];
	}
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self setDoneButtonHidden:!textView.text.nonempty];
	if ([self.delegate respondsToSelector:@selector(composeBarDidEndEditing:)]) {
		[self.delegate composeBarDidEndEditing:self];
	}
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
    [self updateHeight];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSUInteger charactersLimit;
	if ([self.delegate respondsToSelector:@selector(composeBarCharactersLimit:)] && self.height > 44) {
		charactersLimit = [self.delegate composeBarCharactersLimit:self];
	} else {
		charactersLimit = [Constants composeBarDefaultCharactersLimit];
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
