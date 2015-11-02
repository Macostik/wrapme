//
//  WLImageFetcher.m
//  meWrap
//
//  Created by Ravenpod on 24.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLImageFetcher.h"
#import "WLImageCache.h"
#import "WLSystemImageCache.h"
#import "UIView+QuatzCoreAnimations.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+Additions.h"
#import "GCDHelper.h"

@interface WLImageFetcher ()

@property (strong, nonatomic) NSMutableSet* urls;

@property (strong, nonatomic) NSOperationQueue *fetchingQueue;

@end

@implementation WLImageFetcher

+ (instancetype)fetcher {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)setup {
    [super setup];
    self.urls = [NSMutableSet set];
    self.fetchingQueue = [[NSOperationQueue alloc] init];
}

- (id)enqueueImageWithUrl:(NSString *)url receiver:(id)receiver {
    [self.receivers addObject:receiver];
    return [self enqueueImageWithUrl:url];
}

- (void)handleResultForUrl:(NSString*)url block:(void (^)(NSObject <WLImageFetching> *receiver))block {
    [self.urls removeObject:url];
    NSHashTable *receivers = [self.receivers copy];
    
    void (^handler)(id) = ^(id receiver) {
        if ([[receiver fetcherTargetUrl:self] isEqualToString:url]) {
            block(receiver);
            [self.receivers removeObject:receiver];
        }
    };
    
    if (receivers.count == 1) {
        handler([receivers anyObject]);
    } else {
        for (NSObject <WLImageFetching> *receiver in receivers) {
            handler(receiver);
        }
    }
}

- (id)enqueueImageWithUrl:(NSString *)url {
	if (url.nonempty) {
        if ([self.urls containsObject:url]) {
            return nil;
        } else {
            [self.urls addObject:url];
            __weak typeof(self)weakSelf = self;
            WLImageFetcherBlock success = ^(UIImage *image, BOOL cached) {
                [weakSelf handleResultForUrl:url block:^(NSObject<WLImageFetching> *receiver) {
                    [receiver fetcher:weakSelf didFinishWithImage:image cached:cached];
                }];
            };
            
            if ([[WLImageCache cache] containsImageWithUrl:url]) {
                [[WLImageCache cache] imageWithUrl:url completion:success];
            } else if ([url isExistingFilePath]) {
                [self setFileSystemUrl:url completion:success];
            } else {
                return [self setNetworkUrl:url success:success failure:^(NSError *error) {
                    [weakSelf handleResultForUrl:url block:^(NSObject<WLImageFetching> *receiver) {
                        [receiver fetcher:weakSelf didFailWithError:error];
                    }];
                }];
            }
        }
    }
    return nil;
}

- (id)setNetworkUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
    run_getting_object(^id{
        return [UIImage imageWithData:[NSData dataWithContentsOfURL:[url URL]]];
    }, ^(UIImage *image) {
        if (image) {
            [[WLImageCache cache] setImage:image withUrl:url];
            if (success) success(image, NO);
        } else {
            if (failure) failure(nil);
        }
    });
    return nil;
}

- (void)setFileSystemUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
    if (!completion) return;
    UIImage* image = [WLSystemImageCache imageWithIdentifier:url];
    if (image) {
        completion(image, YES);
    } else {
        run_getting_object(^id{
            NSData *data = [NSData dataWithContentsOfFile:url];
            UIImage *image = [UIImage imageWithData:data];
            return image;
        }, ^ (UIImage* image) {
            [WLSystemImageCache setImage:image withIdentifier:url];
            completion(image, NO);
        });
    }
}

@end
