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
#import <AFNetworking/AFURLConnectionOperation.h>
#import "WLUploadingQueue.h"

@interface WLProgressBar ()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIView *progressView;

@end

@implementation WLProgressBar

- (void)awakeFromNib{
    [super awakeFromNib];
	[self setup];
	self.progress = 0.0f;
}

- (void)setBackgroundView:(UIView *)backgroundView {
	[_backgroundView removeFromSuperview];
	_backgroundView = backgroundView;
	[self addSubview:backgroundView];
}

- (void)setProgressView:(UIView *)progressView {
	[_progressView removeFromSuperview];
	_progressView = progressView;
	[self.backgroundView addSubview:progressView];
}

- (void)setup {
	self.backgroundView = [self initializeBackgroundView];
	self.progressView = [self initializeProgressViewWithBackgroundView:self.backgroundView];
}

- (UIView *)initializeBackgroundView {
	WLBorderView *backgroundView = [[WLBorderView alloc] initWithFrame:self.bounds];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	backgroundView.clipsToBounds = YES;
	return backgroundView;
}

- (UIView *)initializeProgressViewWithBackgroundView:(UIView *)backgroundView {
	UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.bounds.size.height)];
	progressView.backgroundColor = [UIColor WL_orangeColor];
	return progressView;
}

- (void)setProgress:(CGFloat)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
	progress = Smoothstep(0, 1, progress);
	float difference = ABS(progress - _progress);
	_progress = progress;
	[self updateProgressViewAnimated:animated difference:difference];
}

- (void)updateProgressViewAnimated:(BOOL)animated difference:(float)difference {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5*_progress];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	self.progressView.frame = CGRectMake(0, 0, _progress * self.backgroundView.width, self.backgroundView.height);
	if (animated) {
		[UIView commitAnimations];
	}
	
	if ([self.delegate respondsToSelector:@selector(progressBar:didChangeProgress:)]) {
		[self.delegate progressBar:self didChangeProgress:_progress];
	}
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
	WLUploadingItem* uploadingItem = [[WLUploadingItem alloc] init];
	uploadingItem.operation = operation;
	self.uploadingItem = uploadingItem;
}

- (void)setUploadingItem:(WLUploadingItem *)uploadingItem {
	self.progress = uploadingItem.progress;
	__weak typeof(self)weakSelf = self;
	[uploadingItem setProgressChangeBlock:^(float progress) {
		[weakSelf setProgress:progress animated:YES];
	}];
}

@end
