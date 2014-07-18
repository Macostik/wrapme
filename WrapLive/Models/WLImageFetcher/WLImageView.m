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

@interface WLImageView () <WLImageFetching>

@property (nonatomic) UIViewContentMode defaultContentMode;

@end

@implementation WLImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.defaultContentMode = self.contentMode;
}

- (void)setUrl:(NSString *)url {
	[self setUrl:url completion:nil];
}

- (void)setUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
    _url = url;
	self.image = nil;
    if (self.contentMode != self.defaultContentMode) {
        self.contentMode = self.defaultContentMode;
    }
	self.completionBlock = completion;
	[[WLImageFetcher fetcher] addReceiver:self];
	[[WLImageFetcher fetcher] enqueueImageWithUrl:url];
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	if (animated) {
        CGFloat alpha = self.alpha;
		self.alpha = 0.0f;
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.33f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.alpha = alpha;
        } completion:^(BOOL finished) {
        }];
	}
	self.image = image;
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
	return self.url;
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
