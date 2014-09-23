//
//  WLImageView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLImageView.h"
#import "WLImageFetcher.h"
#import "NSString+Additions.h"
#import "NSError+WLAPIManager.h"
#import "WLPicture.h"

@interface WLImageView () <WLImageFetching>

@property (nonatomic) UIViewContentMode defaultContentMode;
@property (nonatomic) CGFloat defaultAlpha;

@end

@implementation WLImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.defaultContentMode = self.contentMode;
    self.defaultAlpha = self.alpha;
    [[WLImageFetcher fetcher] addReceiver:self];
}

- (void)setUrl:(NSString *)url {
	[self setUrl:url success:nil failure:nil];
}

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
    self.image = nil;
    _url = url;
    if (self.alpha != self.defaultAlpha) self.alpha = self.defaultAlpha;
    if (self.contentMode != self.defaultContentMode) self.contentMode = self.defaultContentMode;
    self.success = success;
    self.failure = failure;
    if (url.nonempty) {
        [[WLImageFetcher fetcher] enqueueImageWithUrl:url];
    } else {
        [self fetcher:[WLImageFetcher fetcher] didFailWithError:[NSError errorWithDescription:@"Image URL is not valid."]];
    }
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	if (self.animatingPicture.animate || animated) {
        CGFloat alpha = self.alpha;
		self.alpha = 0.0f;
        __weak typeof(self)weakSelf = self;
        NSTimeInterval duration = self.animatingPicture.animate ? 0.5f : 0.33f;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.alpha = alpha;
        } completion:^(BOOL finished) {
            weakSelf.animatingPicture.animate = NO;
        }];
	}
	self.image = image;
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
	return _url;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
	[self setImage:image animated:!cached];
	WLImageFetcherBlock success = self.success;
	if (success) {
		success(image, cached);
		self.success = nil;
	}
    self.failure = nil;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
	WLFailureBlock failure = self.failure;
	if (failure) {
		failure(error);
		self.failure = nil;
	}
    self.success = nil;
    NSString* placeholder = self.placeholderName;
    if (placeholder.nonempty) {
        self.contentMode = UIViewContentModeCenter;
        self.image = [UIImage imageNamed:placeholder];
    }
}

@end
