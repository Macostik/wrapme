//
//  WLFlashSettingsControl.m
//  WrapLive
//
//  Created by Sergey Maximenko on 23.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLFlashModeControl.h"
#import "UIFont+CustomFonts.h"
#import "UIColor+CustomColors.h"
#import "WLButton.h"
#import "WLIcon.h"

@interface WLFlashModeControl ()

@property (weak, nonatomic) UIButton* onButton;
@property (weak, nonatomic) UIButton* offButton;
@property (weak, nonatomic) UIButton* autoButton;
@property (weak, nonatomic) UIButton* currentModeButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation WLFlashModeControl

static inline NSAttributedString *WLFlashModeStringValue(AVCaptureFlashMode mode) {
    FAKIcon *icon = nil;
    switch (mode) {
        case AVCaptureFlashModeOn:
            icon = [WLIcon iconWithName:@"wl-flashOn"];
            break;
        case AVCaptureFlashModeOff:
            icon = [WLIcon iconWithName:@"wl-flashOff"];
            break;
        case AVCaptureFlashModeAuto:
            icon = [WLIcon iconWithName:@"wl-flashAuto"];
            break;
        default:
            icon = [WLIcon iconWithName:@"wl-flashOn"];
            break;
    }
    return [icon attributedString];
};

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.currentModeButton = [self initializeButton:nil action:@selector(changeMode:)];
	self.currentModeButton.width = self.height;
	self.onButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeOn) action:@selector(selectOn:)];
	self.offButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeOff) action:@selector(selectOff:)];
	self.autoButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeAuto) action:@selector(selectAuto:)];
    
	self.mode = AVCaptureFlashModeOn;
	self.selecting = NO;
}

- (UIButton*)initializeButton:(NSAttributedString*)title action:(SEL)action {
	CGRect frame = CGRectMake(0, 0, self.height, self.height);
	WLButton* button = [WLButton buttonWithType:UIButtonTypeCustom];
	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	button.frame = frame;
	[button setAttributedTitle:title forState:UIControlStateNormal];
	[self addSubview:button];
	return button;
}

- (void)setMode:(AVCaptureFlashMode)mode {
	[self setMode:mode animated:NO];
}

- (void)setMode:(AVCaptureFlashMode)mode animated:(BOOL)animated {
	_mode = mode;
	[self.currentModeButton setAttributedTitle:WLFlashModeStringValue(mode) forState:UIControlStateNormal];
}

- (void)setSelecting:(BOOL)selecting {
	[self setSelecting:selecting animated:NO];
}

- (void)setSelecting:(BOOL)selecting animated:(BOOL)animated {
	_selecting = selecting;
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	}
	self.currentModeButton.alpha = selecting ? 0.0f : 1.0f;
	self.onButton.alpha = selecting ? 1.0f : 0.0f;
	self.offButton.alpha = selecting ? 1.0f : 0.0f;
	self.autoButton.alpha = selecting ? 1.0f : 0.0f;
	CGFloat buttonWidth = self.height;
	self.offButton.x = selecting ? buttonWidth : 0.0f;
	self.autoButton.x = selecting ? (2.0f * buttonWidth) : 0.0f;
    self.widthConstraint.constant = selecting ? buttonWidth * 3 : self.height;
    [self layoutIfNeeded];
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)selectMode:(AVCaptureFlashMode)mode {
	[self setMode:mode animated:YES];
	[self setSelecting:NO animated:YES];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark- Actions

- (void)changeMode:(UIButton*)sender {
	[self setSelecting:!_selecting animated:YES];
}

- (void)selectOn:(UIButton*)sender {
	[self selectMode:AVCaptureFlashModeOn];
}

- (void)selectOff:(UIButton*)sender {
	[self selectMode:AVCaptureFlashModeOff];
}

- (void)selectAuto:(UIButton*)sender {
	[self selectMode:AVCaptureFlashModeAuto];
}

@end
