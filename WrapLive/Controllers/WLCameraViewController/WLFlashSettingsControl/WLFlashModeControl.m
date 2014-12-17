//
//  WLFlashSettingsControl.m
//  WrapLive
//
//  Created by Sergey Maximenko on 23.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLFlashModeControl.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "UIColor+CustomColors.h"
#import "WLButton.h"

@interface WLFlashModeControl ()

@property (weak, nonatomic) UIButton* onButton;
@property (weak, nonatomic) UIButton* offButton;
@property (weak, nonatomic) UIButton* autoButton;
@property (weak, nonatomic) UIButton* currentModeButton;

@end

@implementation WLFlashModeControl

static inline NSString *WLFlashModeStringValue(AVCaptureFlashMode mode) {
	switch (mode) {
		case AVCaptureFlashModeOn:
			return @"On";
			break;
		case AVCaptureFlashModeOff:
			return @"Off";
			break;
		case AVCaptureFlashModeAuto:
			return @"Auto";
			break;
		default:
			return @"On";
			break;
	}
};

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.currentModeButton = [self initializeButton:nil action:@selector(changeMode:)];
	self.currentModeButton.width = self.width/2;
	[self.currentModeButton setImage:[UIImage imageNamed:@"ic_flash"] forState:UIControlStateNormal];
	self.onButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeOn) action:@selector(selectOn:)];
	[self.onButton setImage:[UIImage imageNamed:@"ic_flash"] forState:UIControlStateNormal];
	self.offButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeOff) action:@selector(selectOff:)];
	self.autoButton = [self initializeButton:WLFlashModeStringValue(AVCaptureFlashModeAuto) action:@selector(selectAuto:)];
	
	self.mode = AVCaptureFlashModeOn;
	self.selecting = NO;
}

- (UIColor *)titleColor {
	return [self.currentModeButton titleColorForState:UIControlStateNormal];
}

- (void)setTitleColor:(UIColor *)titleColor {
	[self.currentModeButton setTitleColor:titleColor forState:UIControlStateNormal];
	[self.onButton setTitleColor:titleColor forState:UIControlStateNormal];
	[self.offButton setTitleColor:titleColor forState:UIControlStateNormal];
	[self.autoButton setTitleColor:titleColor forState:UIControlStateNormal];
}

- (UIButton*)initializeButton:(NSString*)title action:(SEL)action {
	CGRect frame = CGRectMake(0, 0, self.width/3, self.height);
	WLButton* button = [WLButton buttonWithType:UIButtonTypeCustom];
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	button.frame = frame;
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitle:title forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont fontWithName:WLFontOpenSansRegular preset:WLFontPresetSmall];
    button.preset = WLFontPresetSmall;
	[self addSubview:button];
	return button;
}

- (void)setMode:(AVCaptureFlashMode)mode {
	[self setMode:mode animated:NO];
}

- (void)setMode:(AVCaptureFlashMode)mode animated:(BOOL)animated {
	_mode = mode;
	[self.currentModeButton setTitle:WLFlashModeStringValue(mode) forState:UIControlStateNormal];
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
	CGFloat width = (self.width / 3.0f);
	self.offButton.x = selecting ? width : 0.0f;
	self.autoButton.x = selecting ? (2.0f * width) : 0.0f;
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
