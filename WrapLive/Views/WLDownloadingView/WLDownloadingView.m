//
//  WLDownloadingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import "NSObject+NibAdditions.h"
#import "WLProgressBar+WLContribution.h"
#import "WLCandy+Extended.h"
#import "WLNavigationHelper.h"
#import "WLUploadPhotoViewController.h"

@interface WLDownloadingView () <WLImageFetching, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (weak, nonatomic) WLCandy *candy;

@property (strong, nonatomic) WLImageBlock successBlock;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@end

@implementation WLDownloadingView

+ (void)downloadAndEditCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    WLImageBlock downloadBlock = ^(UIImage *image) {
        [AdobeUXImageEditorViewController editImage:image completion:^(UIImage *image) {
            if (candy.valid) {
                [WLPicture picture:image completion:^(WLPicture *picture) {
                    [candy setEditedPictureIfNeeded:picture];
                    [candy enqueueUpdate:failure];
                }];
            } else {
                if (failure) failure(nil);
            }
        } cancel:nil];
    };
    [WLDownloadingView downloadingViewForCandy:candy success:downloadBlock failure:failure];
}

+ (instancetype)downloadingViewForCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    return [self downloadingView:[UIWindow mainWindow] forCandy:candy success:success failure:failure];
}

+ (instancetype)downloadingView:(UIView *)view
                       forCandy:(WLCandy *)candy
                        success:(WLImageBlock)success
                        failure:(WLFailureBlock)failure {
    return  [[WLDownloadingView loadFromNib] downloadingView:view
                                                    forCandy:candy
                                                     success:success
                                                     failure:failure];
}

- (instancetype)downloadingView:(UIView *)view
                       forCandy:(WLCandy *)candy
                        success:(WLImageBlock)success
                        failure:(WLFailureBlock)failure {
    self.frame = view.frame;
    self.candy = candy;
    [view addSubview:self];
    [self setFullFlexible];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    
    self.alpha = 0.0f;
    
    id operation = [self downloadEntry:success failureBlock:failure];
    if (operation) {
        [self.progressBar setOperation:operation];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1
              initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.alpha = 1.0f;
                         } completion:^(BOOL finished) {
                         }];
    }
    return self;
}

- (void)setCandy:(WLCandy *)candy {
    _candy = candy;
    [[WLCandy notifier] addReceiver:self];
}

- (IBAction)calcel:(id)sender {
    [[WLImageFetcher fetcher] removeReceiver:self];
    [self dissmis];
}

- (void)dissmis {
    __weak typeof(self)weakSelf = self;
    if (self.alpha == 0) {
        [weakSelf removeFromSuperview];
    } else {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1
              initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             weakSelf.alpha = 0.0f;
                         } completion:^(BOOL finished) {
                             [weakSelf removeFromSuperview];
                         }];
    }
}

- (id)downloadEntry:(WLImageBlock)success failureBlock:(WLFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
    [[WLImageFetcher fetcher] addReceiver:self];
    return [[WLImageFetcher fetcher] enqueueImageWithUrl:self.candy.picture.original];
}

// MARK: - WLImageFetching

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    if (self.failureBlock) self.failureBlock([WLNetwork network].reachable ? error : WLError(WLLS(@"editing_internet_connection_error")));
    [self dissmis];
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    if (self.successBlock) self.successBlock(image);
    [self dissmis];
}

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
    return self.candy.picture.original;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier entryDeleted:(WLEntry *)entry {
    if (self.failureBlock) self.failureBlock(nil);
    [self dissmis];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.candy == entry;
}

@end
