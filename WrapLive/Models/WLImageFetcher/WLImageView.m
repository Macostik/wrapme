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
	[self setUrl:url completion:nil];
}

- (void)setUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
    self.image = nil;
    _url = url;
    [self.layer removeAllAnimations];
    if (self.alpha != self.defaultAlpha) self.alpha = self.defaultAlpha;
    if (self.contentMode != self.defaultContentMode) self.contentMode = self.defaultContentMode;
    self.completionBlock = completion;
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
            weakSelf.animatingPicture.animate = NO;
        } completion:^(BOOL finished) {
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
	WLImageFetcherBlock completionBlock = self.completionBlock;
	if (completionBlock) {
		completionBlock(image, cached, nil);
		self.completionBlock = nil;
	}
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
	WLImageFetcherBlock completionBlock = self.completionBlock;
	if (completionBlock) {
		completionBlock(nil, NO, error);
		self.completionBlock = nil;
	}
    NSString* placeholderName = self.placeholderName;
    if (placeholderName.nonempty) {
        self.contentMode = UIViewContentModeCenter;
        self.image = [UIImage imageNamed:placeholderName];
    }
}

@end
