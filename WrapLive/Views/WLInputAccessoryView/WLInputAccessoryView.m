//
//  WLInputAccessoryView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLInputAccessoryView.h"
#import "NSObject+NibAdditions.h"

@interface WLInputAccessoryView ()

@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet UIButton* doneButton;

@property (strong, nonatomic) NSString* text;

@end

@implementation WLInputAccessoryView

+ (instancetype)inputAccessoryViewWithResponder:(UIResponder *)responder {
	WLInputAccessoryView* inputAccessoryView = [WLInputAccessoryView loadFromNib];
	inputAccessoryView.responder = responder;
	[inputAccessoryView.cancelButton addTarget:inputAccessoryView action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	[inputAccessoryView.doneButton addTarget:inputAccessoryView action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
	if ([responder respondsToSelector:@selector(setInputAccessoryView:)]) {
		[responder performSelector:@selector(setInputAccessoryView:) withObject:inputAccessoryView];
	}
	return inputAccessoryView;
}

+ (instancetype)inputAccessoryViewWithTarget:(id)target cancel:(SEL)cancel done:(SEL)done {
	WLInputAccessoryView* inputAccessoryView = [WLInputAccessoryView loadFromNib];
	[inputAccessoryView.cancelButton addTarget:target action:cancel forControlEvents:UIControlEventTouchUpInside];
	[inputAccessoryView.doneButton addTarget:target action:done forControlEvents:UIControlEventTouchUpInside];
	return inputAccessoryView;
}

- (void)cancel:(id)sender {
	if ([self.responder respondsToSelector:@selector(setText:)]) {
		[self.responder performSelector:@selector(setText:) withObject:self.text];
	}
	[self.responder resignFirstResponder];
}

- (void)done:(id)sender {
	[self.responder resignFirstResponder];
}

- (void)didMoveToSuperview {
	if (self.superview != nil && [self.responder respondsToSelector:@selector(text)]) {
		self.text = [self.responder performSelector:@selector(text) withObject:nil];
	}
}

@end
