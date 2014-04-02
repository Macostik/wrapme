//
//  WLProgressView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 02.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLProgressView.h"
#import "WLProgressBar.h"
#import "NSObject+NibAdditions.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import <AFNetworking/AFURLConnectionOperation.h>

static const CGFloat spacing = 8;

@interface WLProgressView ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation WLProgressView

+ (instancetype)instance {
    static id instance = nil;
    if (instance == nil) {
        instance = [self loadFromNib];
    }
    return instance;
}

+ (void)showWithMessage:(NSString*)message image:(UIImage*)image operation:(AFURLConnectionOperation *)operation {
	WLProgressView* instance = [self instance];
	instance.messageLabel.text = message;
	
	instance.imageView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:instance.imageView.retinaSize interpolationQuality:kCGInterpolationDefault];
	
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	instance.frame = window.bounds;
	[instance layoutSubviews];
	[window addSubview:instance];
	
	instance.alpha = 0.0f;
	[UIView animateWithDuration:0.25f animations:^{
		instance.alpha = 1.0f;
	}];
	
	instance.progressBar.progress = 0;

	[operation setUploadProgressBlock:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
		float progress = ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
		[instance.progressBar setProgress:progress animated:YES];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
		float progress = ((float)totalBytesRead/(float)totalBytesExpectedToRead);
		[instance.progressBar setProgress:progress animated:YES];
	}];
}

+ (void)showWithMessage:(NSString*)message operation:(AFURLConnectionOperation *)operation {
	[self showWithMessage:message image:nil operation:operation];
}

+ (void)dismiss {
	WLProgressView* instance = [self instance];
	[UIView animateWithDuration:0.25f animations:^{
		instance.alpha = 0.0f;
	} completion:^(BOOL finished) {
		[instance removeFromSuperview];
		instance.messageLabel.text = nil;
		instance.imageView.image = nil;
	}];
}

- (void)layoutSubviews {
	self.imageView.hidden = (self.imageView.image == nil);
	
	CGFloat x;
	
	if (self.imageView.hidden) {
		x = spacing;
	} else {
		x = CGRectGetMaxX(self.imageView.frame) + spacing;
	}
	
	CGFloat width = self.contentView.width - x - spacing;
	
	self.progressBar.x = x;
	self.progressBar.width = width;
	
	self.messageLabel.x = x;
	self.messageLabel.width = width;
}

@end
