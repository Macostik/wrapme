//
//  WLDownloadingView.m
//  meWrap
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import "NSObject+NibAdditions.h"
#import "WLProgressBar+WLContribution.h"
#import "WLNetwork.h"
#import "WLImageFetcher.h"

@interface WLDownloadingView () <WLImageFetching, EntryNotifying>

@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (weak, nonatomic) IBOutlet UILabel *downloadingMediaLabel;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (weak, nonatomic) Candy *candy;

@end

@implementation WLDownloadingView

+ (instancetype)downloadCandy:(Candy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    return [[WLDownloadingView loadFromNib] downloadCandy:candy success:success failure:failure];
}

- (instancetype)downloadCandy:(Candy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    UIView *view = [UIWindow mainWindow];
    self.frame = view.frame;
    self.candy = candy;
    [view addSubview:self];
    [self setFullFlexible];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    
    self.alpha = 0.0f;

   [self downloadEntry:success failure:failure];
    
    return self;
}

- (void)setCandy:(Candy *)candy {
    _candy = candy;
    [[Candy notifier] addReceiver:self];
}

- (IBAction)cancel:(id)sender {
    [[WLImageFetcher defaultFetcher] removeReceiver:self];
    [self dissmis];
}

- (void)showDownloadingView {
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

- (void)downloadEntry:(WLImageBlock)success failure:(WLFailureBlock)failure {
    NSString *url = self.candy.picture.original;
    if ([[WLImageCache defaultCache] containsImageWithUrl:url]) {
        [[WLImageCache defaultCache] imageWithUrl:url completion:^(UIImage *image, BOOL cached) {
            if (success) {
                success(image);
            }
        }];
    } else if ([url isExistingFilePath]) {
        [[WLImageFetcher defaultFetcher] setFileSystemUrl:url completion:^(UIImage *image, BOOL cached) {
            if (success) {
                success(image);
            }
        }];
    } else {
        __weak __typeof(self)weakSelf = self;
        [self showDownloadingView];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFImageResponseSerializer serializer];
        operation.securityPolicy.allowInvalidCertificates = YES;
        operation.securityPolicy.validatesDomainName = NO;
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[WLImageCache defaultCache] setImage:responseObject withUrl:url];
            if (success) success(responseObject);
            [weakSelf dissmis];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error.code != NSURLErrorCancelled && failure) failure(error);
            [weakSelf dissmis];
        }];
        [[[NSOperationQueue alloc] init] addOperation:operation];
        [self.progressBar setOperation:operation];
        self.operation = operation;
    }
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    self.candy = nil;
    if (self.operation) {
        [self.operation cancel];
    }
    [self dissmis];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteContainer:(Entry *)entry {
    self.candy = nil;
    if (self.operation) {
        [self.operation cancel];
    }
    [self dissmis];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.candy == entry;
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnContainer:(Entry *)entry {
    return self.candy.wrap == entry;
}

@end
