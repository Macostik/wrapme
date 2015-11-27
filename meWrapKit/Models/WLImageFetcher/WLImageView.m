//
//  WLImageView.m
//  meWrap
//
//  Created by Ravenpod on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLImageView.h"

@interface WLImageView () <ImageFetching>

@property (strong, nonatomic) UIColor *originalBackgroundColor;

@end

@implementation WLImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.originalBackgroundColor = self.backgroundColor;
}

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

- (void)setUrl:(NSString *)url success:(void (^)(UIImage *, BOOL))success failure:(WLFailureBlock)failure {
    self.image = nil;
    _url = url;
    self.success = success;
    self.failure = failure;
    if (url.nonempty) {
        [self setDefaultIconViewHidden:YES];
        [[ImageFetcher defaultFetcher] enqueue:url receiver:self];
    } else {
        [self setDefaultIconViewHidden:NO];
    }
}

- (void)setDefaultIconViewHidden:(BOOL)defaultIconViewHidden {
    self.defaultIconView.hidden = defaultIconViewHidden;
    if (defaultIconViewHidden) {
        self.backgroundColor = self.originalBackgroundColor;
    } else {
        if (self.defaultBackgroundColor) {
            self.backgroundColor = self.defaultBackgroundColor;
        }
    }
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
    self.image = image;
    if (animated) {
        [self addAnimation:[CATransition transition:kCATransitionFade]];
    }
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(ImageFetcher *)fetcher {
	return _url;
}

- (void)fetcher:(ImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setDefaultIconViewHidden:YES];
	[self setImage:image animated:!cached];
	void (^success)(UIImage *, BOOL) = self.success;
	if (success) {
		success(image, cached);
		self.success = nil;
	}
    self.failure = nil;
}

- (void)fetcher:(ImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setDefaultIconViewHidden:NO];
	WLFailureBlock failure = self.failure;
	if (failure) {
		failure(error);
		self.failure = nil;
	}
    self.success = nil;
}

@end
