//
//  WLDownloadingView.m
//  meWrap
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import <AFNetworking/AFNetworking.h>

@interface WLDownloadingView () <ImageFetching, EntryNotifying>

@property (weak, nonatomic) IBOutlet ProgressBar *progressBar;

@property (weak, nonatomic) IBOutlet UILabel *downloadingMediaLabel;

@property (weak, nonatomic) NSURLSessionDataTask *task;

@property (weak, nonatomic) Candy *candy;

@end

@implementation WLDownloadingView

+ (void)downloadCandy:(Candy *)candy success:(ImageBlock)success failure:(FailureBlock)failure {
    NSString *url = candy.asset.original;
    NSString *uid = [ImageCache uidFromURL:url];
    if ([[ImageCache defaultCache] contains:uid]) {
        success([[ImageCache defaultCache] read:uid]);
    } else if ([url isExistingFilePath]) {
        UIImage *image = [InMemoryImageCache instance][url];
        if (image == nil) {
            image = [UIImage imageWithContentsOfFile:url];
            [InMemoryImageCache instance][url] = image;
        }
        success(image);
    } else {
        [[WLDownloadingView loadFromNib:@"WLDownloadingView"] downloadCandy:candy success:success failure:failure];
    }
}

- (instancetype)downloadCandy:(Candy *)candy success:(ImageBlock)success failure:(FailureBlock)failure {
    [[Candy notifier] addReceiver:self];
    UIView *view = [UIWindow mainWindow];
    self.frame = view.frame;
    self.candy = candy;
    [view addSubview:self];
    [self setFullFlexible];
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    self.alpha = 0.0f;
    [UIView animateWithDuration:0.5f animations:^{
        self.alpha = 1.0f;
    }];
    [self download:success failure:failure];
    return self;
}

- (IBAction)cancel:(id)sender {
    self.candy = nil;
    [self.task cancel];
    [self dissmis];
}

- (void)dissmis {
    [UIView animateWithDuration:0.5f animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)download:(ImageBlock)success failure:(FailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    NSString *url = self.candy.asset.original;
    NSString *uid = [ImageCache uidFromURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    self.task = [manager GET:url parameters:nil progress:[self.progressBar downloadProgress] success:^(NSURLSessionDataTask *task, id responseObject) {
        UIImage *image = responseObject;
        [[ImageCache defaultCache] write:image uid:uid];
        if (success) success(image);
        [weakSelf dissmis];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (error.code != NSURLErrorCancelled && failure) failure(error);
        [weakSelf dissmis];
    }];
    [self.task resume];
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    [self cancel:nil];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteContainer:(Entry *)entry {
    [self cancel:nil];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.candy == entry;
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnContainer:(Entry *)entry {
    return self.candy.wrap == entry;
}

@end
