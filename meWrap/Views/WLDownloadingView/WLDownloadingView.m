//
//  WLDownloadingView.m
//  meWrap
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import "WLProgressBar+WLContribution.h"

@interface WLDownloadingView () <ImageFetching, EntryNotifying>

@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (weak, nonatomic) IBOutlet UILabel *downloadingMediaLabel;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (weak, nonatomic) Candy *candy;

@end

@implementation WLDownloadingView

+ (instancetype)downloadCandy:(Candy *)candy success:(ImageBlock)success failure:(FailureBlock)failure {
    return [[WLDownloadingView loadFromNib:@"WLDownloadingView"] downloadCandy:candy success:success failure:failure];
}

- (instancetype)downloadCandy:(Candy *)candy success:(ImageBlock)success failure:(FailureBlock)failure {
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

- (void)downloadEntry:(ImageBlock)success failure:(FailureBlock)failure {
    NSString *url = self.candy.asset.original;
    NSString *uid = [ImageCache uidFromURL:url];
    if ([[ImageCache defaultCache] contains:uid]) {
        if (success) {
            success([[ImageCache defaultCache] read:uid]);
        }
    } else if ([url isExistingFilePath]) {
        
        UIImage *image = [InMemoryImageCache instance][url];
        if (image == nil) {
            image = [UIImage imageWithContentsOfFile:url];
            [InMemoryImageCache instance][url] = image;
        }
        if (success) {
            success(image);
        }
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
            [[ImageCache defaultCache] write:responseObject uid:uid];
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
