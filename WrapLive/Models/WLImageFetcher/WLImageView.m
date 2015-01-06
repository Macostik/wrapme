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

@property (strong, nonatomic) NSMutableDictionary* states;

@end

@implementation WLImageView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[WLImageFetcher fetcher] addReceiver:self];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[WLImageFetcher fetcher] addReceiver:self];
    }
    return self;
}

- (NSMutableDictionary *)states {
    if (!_states) {
        _states = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionary],@(WLImageViewStateEmpty),[NSMutableDictionary dictionary],@(WLImageViewStateEmpty), nil];
    }
    return _states;
}

- (void)setUrl:(NSString *)url {
	[self setUrl:url success:nil failure:nil];
}

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
    self.image = nil;
    _url = url;
    self.success = success;
    self.failure = failure;
    self.state = WLImageViewStateDefault;
    if (url.nonempty) {
        [[WLImageFetcher fetcher] enqueueImageWithUrl:url];
    } else {
        self.state = WLImageViewStateEmpty;
    }
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	if (self.animatingPicture.animate || animated) {
        CGFloat alpha = self.alpha;
		self.alpha = 0.0f;
        __weak typeof(self)weakSelf = self;
        NSTimeInterval duration = self.animatingPicture.animate ? 0.5f : 0.33f;
        self.animatingPicture.animate = NO;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.alpha = alpha;
        } completion:^(BOOL finished) {
        }];
	}
	self.image = image;
}

- (void)setState:(WLImageViewState)state {
    if (_state != state) {
        _state = state;
        if (state == WLImageViewStateDefault) {
            self.contentMode = UIViewContentModeScaleAspectFill;
        } else {
            NSMutableDictionary *stateInfo = self.states[@(state)];
            if (stateInfo[@"contentMode"] != nil) {
                self.contentMode = [stateInfo[@"contentMode"] integerValue];
            }
            if (stateInfo[@"imageName"] != nil) {
                self.image = [UIImage imageNamed:stateInfo[@"imageName"]];
            }
        }
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode forState:(WLImageViewState)state {
    NSMutableDictionary *stateInfo = self.states[@(state)];
    stateInfo[@"contentMode"] = @(contentMode);
}

- (void)setImageName:(NSString *)imageName forState:(WLImageViewState)state {
    NSMutableDictionary *stateInfo = self.states[@(state)];
    if (imageName) {
        stateInfo[@"imageName"] = imageName;
    } else {
        [stateInfo removeObjectForKey:@"imageName"];
    }
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
	return _url;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    self.state = WLImageViewStateDefault;
	[self setImage:image animated:!cached];
	WLImageFetcherBlock success = self.success;
	if (success) {
		success(image, cached);
		self.success = nil;
	}
    self.failure = nil;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    self.state = WLImageViewStateFailed;
	WLFailureBlock failure = self.failure;
	if (failure) {
		failure(error);
		self.failure = nil;
	}
    self.success = nil;
}

@end
