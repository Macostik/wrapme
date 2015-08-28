//
//  WLDownloadingView.m
//  moji
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
#import "AdobeUXImageEditorViewController+SharedEditing.h"

@interface WLDownloadingView () <WLImageFetching, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (weak, nonatomic) WLCandy *candy;

@property (strong, nonatomic) WLImageBlock successBlock;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@end

@implementation WLDownloadingView

+ (instancetype)downloadCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    return [[WLDownloadingView loadFromNib] downloadCandy:candy success:success failure:failure];
}

- (instancetype)downloadCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    UIView *view = [UIWindow mainWindow];
    self.frame = view.frame;
    self.candy = candy;
    [view addSubview:self];
    [self setFullFlexible];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    
    self.alpha = 0.0f;
    
    __weak typeof(self)weakSelf = self;
    id operation = [self downloadEntry:success failure:failure];
    if (operation) {
        [weakSelf.progressBar setOperation:operation];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1
              initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             weakSelf.alpha = 1.0f;
                         } completion:^(BOOL finished) {
                         }];
    }
    
    return self;
}

- (void)setCandy:(WLCandy *)candy {
    _candy = candy;
    [[WLCandy notifier] addReceiver:self];
}

- (IBAction)cancel:(id)sender {
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

- (id)downloadEntry:(WLImageBlock)success failure:(WLFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
    return [[WLImageFetcher fetcher] enqueueImageWithUrl:self.candy.picture.original receiver:self];
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

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLEntry *)entry {
    self.candy = nil;
    if (self.failureBlock) self.failureBlock(nil);
    [self dissmis];
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteContainer:(WLEntry *)entry {
    self.candy = nil;
    if (self.failureBlock) self.failureBlock(nil);
    [self dissmis];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.candy == entry;
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnContainer:(WLEntry *)entry {
    return self.candy.wrap == entry;
}

@end
