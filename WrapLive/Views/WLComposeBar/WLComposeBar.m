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

static NSUInteger WLComposeBarDefaultCharactersLimit = 360;

@interface WLComposeBar () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation WLComposeBar

- (void)awakeFromNib {
	[super awakeFromNib];
	UIView* composeView = [UIView loadFromNibNamed:@"WLComposeBar" ownedBy:self];
	composeView.frame = self.bounds;
    [self addSubview:composeView];
	self.textField.superview.layer.borderColor = [UIColor WL_grayColor].CGColor;
	self.textField.superview.layer.borderWidth = 0.5f;
	[self updateStateAnimated:NO];
}

- (NSString *)text {
	return self.textField.text;
}

- (void)setText:(NSString *)text {
	self.textField.text = text;
	[self updateStateAnimated:YES];
}

- (void)updateStateAnimated:(BOOL)animated {
	[self setDoneButtonHidden:(self.textField.text.length == 0) animated:animated];
}

- (NSString *)placeholder {
	return self.textField.placeholder;
}

- (void)setPlaceholder:(NSString *)placeHolder {
	self.textField.placeholder = placeHolder;
}

- (void)finish {
	BOOL shouldResign = YES;
	if ([self.delegate respondsToSelector:@selector(composeBarDidShouldResignOnFinish:)]) {
		shouldResign = [self.delegate composeBarDidShouldResignOnFinish:self];
	}
	if (shouldResign) {
		[self.textField resignFirstResponder];
	}
	[self.delegate composeBar:self didFinishWithText:self.textField.text];
	self.text = nil;
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden {
	[self setDoneButtonHidden:doneButtonHidden animated:NO];
}

- (void)setDoneButtonHidden:(BOOL)hidden animated:(BOOL)animated {
	CGFloat x = hidden ? self.width : (self.width - self.doneButton.width);
	if (x != self.doneButton.x) {
		_doneButtonHidden = hidden;
		CGFloat width = (x - self.textField.superview.x - (hidden ? 10 : 0));
		if (animated) {
			[UIView beginAnimations:nil context:nil];
		}
		self.doneButton.x = x;
		self.textField.superview.width = width;
		if (animated) {
			[UIView commitAnimations];
		}
	}
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self finish];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	[self updateStateAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self.delegate composeBarDidReturn:self];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	if ([self.delegate respondsToSelector:@selector(composeBarDidBeginEditing:)]) {
		[self.delegate composeBarDidBeginEditing:self];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if ([self.delegate respondsToSelector:@selector(composeBarDidEndEditing:)]) {
		[self.delegate composeBarDidEndEditing:self];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSUInteger charactersLimit;
	if ([self.delegate respondsToSelector:@selector(composeBarCharactersLimit:)]) {
		charactersLimit = [self.delegate composeBarCharactersLimit:self];
	} else {
		charactersLimit = WLComposeBarDefaultCharactersLimit;
	}
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= charactersLimit;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
	return [self.textField canBecomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
	return [self.textField canResignFirstResponder];
}

- (BOOL)isFirstResponder {
	return [self.textField isFirstResponder];
}

- (BOOL)becomeFirstResponder {
	return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [self.textField resignFirstResponder];
}

@end
