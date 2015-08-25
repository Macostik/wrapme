//
//  WLImageView.m
//  moji
//
//  Created by Ravenpod on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLImageView.h"
#import "WLImageFetcher.h"
#import "NSString+Additions.h"
#import "NSError+WLAPIManager.h"
#import "WLPicture.h"
#import "UIView+QuatzCoreAnimations.h"

@interface WLImageView () <WLImageFetching>

@property (strong, nonatomic) UIColor *originalBackgroundColor;

@end

@implementation WLImageView

- (UIColor *)defaultIconColor {
    if (!_defaultIconColor) _defaultIconColor = [UIColor whiteColor];
    return _defaultIconColor;
}

- (CGFloat)defaultIconSize {
    if (_defaultIconSize == 0) _defaultIconSize = 24;
    return _defaultIconSize;
}

- (UILabel *)defaultIconView {
    if (!_defaultIconView) {
        _defaultIconView = [[UILabel alloc] init];
        _defaultIconView.translatesAutoresizingMaskIntoConstraints = NO;
        _defaultIconView.hidden = YES;
        _defaultIconView.font = [UIFont fontWithName:@"icons" size:self.defaultIconSize];
        _defaultIconView.textAlignment = NSTextAlignmentCenter;
        _defaultIconView.textColor = self.defaultIconColor;
        _defaultIconView.text = self.defaultIconText;
        [self addSubview:_defaultIconView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_defaultIconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_defaultIconView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }
    return _defaultIconView;
}

- (void)setUrl:(NSString *)url {
	[self setUrl:url success:nil failure:nil];
}

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
    self.image = nil;
    _url = url;
    self.success = success;
    self.failure = failure;
    if (url.nonempty) {
        [self setDefaultIconViewHidden:YES];
        [[WLImageFetcher fetcher] enqueueImageWithUrl:url receiver:self];
    } else {
        [self setDefaultIconViewHidden:NO];
    }
}

- (void)setDefaultIconViewHidden:(BOOL)defaultIconViewHidden {
    if (self.defaultIconView.hidden != defaultIconViewHidden) {
        self.defaultIconView.hidden = defaultIconViewHidden;
        if (defaultIconViewHidden) {
            if (self.originalBackgroundColor) {
                self.backgroundColor = self.originalBackgroundColor;
            }
        } else {
            if (self.defaultBackgroundColor) {
                self.originalBackgroundColor = self.backgroundColor;
                self.backgroundColor = self.defaultBackgroundColor;
            }
        }
    }
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
    WLAnimation *animation = self.animatingPicture.animation;
	if (animation) {
        self.alpha = 0.0f;
        __weak typeof(self)weakSelf = self;
        [animation setAnimationBlock:^ (WLAnimation *animation, UIView *view) {
            if (view == weakSelf) {
                view.alpha = animation.progressRatio;
            }
        }];
        animation.view = self;
        [animation start];
    } else if (animated) {
        self.hidden = YES;
        self.alpha = 1.0f;
        [self fade];
        self.hidden = NO;
    } else {
        self.alpha = 1.0f;
    }
	self.image = image;
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
	return _url;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setDefaultIconViewHidden:YES];
	[self setImage:image animated:!cached];
	WLImageFetcherBlock success = self.success;
	if (success) {
		success(image, cached);
		self.success = nil;
	}
    self.failure = nil;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setDefaultIconViewHidden:NO];
	WLFailureBlock failure = self.failure;
	if (failure) {
		failure(error);
		self.failure = nil;
	}
    self.success = nil;
}

@end
