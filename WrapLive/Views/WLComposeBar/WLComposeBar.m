//
//  WLComposeBar.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLComposeBar.h"
#import "NSObject+NibAdditions.h"

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
	self.doneButton.enabled = self.textField.text.length > 0;
}

- (NSString *)text {
	return self.textField.text;
}

- (void)setText:(NSString *)text {
	self.textField.text = text;
	self.doneButton.enabled = self.textField.text.length > 0;
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

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self finish];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	self.doneButton.enabled = sender.text.length > 0;
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
	self.text = nil;
	return [self.textField resignFirstResponder];
}

@end
