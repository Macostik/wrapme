//
//  PGProgressBar.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLProgressBar.h"
#import "UIView+Shorthand.h"
#import "UIColor+CustomColors.h"
#import "WLBorderView.h"
#import "WLSupportFunctions.h"

@interface WLProgressBar ()

@property (strong, nonatomic) WLBorderView *backgroundView;
@property (strong, nonatomic) UIView *progressView;

@end

@implementation WLProgressBar

- (void)awakeFromNib{
    [super awakeFromNib];
	self.backgroundView = [[WLBorderView alloc] initWithFrame:self.bounds];
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	self.backgroundView.clipsToBounds = YES;
	self.progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 5)];
	self.progressView.backgroundColor = [UIColor WL_orangeColor];
	[self.backgroundView addSubview:self.progressView];
	[self addSubview:self.backgroundView];
	
	self.progress = 0.0f;
}

- (void)setProgress:(CGFloat)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
	_progress = Smoothstep(0, 1, progress);
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5*_progress];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	self.progressView.frame = CGRectMake(0, 0, _progress * self.backgroundView.width, self.backgroundView.height);
	if (animated) {
		[UIView commitAnimations];
	}
}

@end
