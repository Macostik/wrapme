//
//  WLImageFetcher.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImageFetcher.h"
#import "WLImageCache.h"
#import "WLSystemImageCache.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "UIView+QuatzCoreAnimations.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+Additions.h"

@interface WLImageFetcher ()

@property (strong, nonatomic) NSMutableSet* urls;

@property (strong, nonatomic) NSOperationQueue *fetchingQueue;

@property (strong, nonatomic) AFImageResponseSerializer *imageResponseSerializer;

@end

@implementation WLImageFetcher

+ (instancetype)fetcher {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.urls = [NSMutableSet set];
        NSOperationQueue *fetchingQueue = [[NSOperationQueue alloc] init];
        fetchingQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        self.fetchingQueue = fetchingQueue;
        self.imageResponseSerializer = [AFImageResponseSerializer serializer];
    }
    return self;
}

- (instancetype)initWithReceiver:(id<WLImageFetching>)receiver {
    return [super initWithReceiver:receiver];
}

- (void)addReceiver:(id<WLImageFetching>)receiver {
	[super addReceiver:receiver];
}

- (void)enqueueImageWithUrl:(NSString *)url {
	if (!url.nonempty || [self.urls containsObject:url]) {
		return;
	}
	
	[self.urls addObject:url];
    __weak typeof(self)weakSelf = self;
    WLImageFetcherBlock success = ^(UIImage *image, BOOL cached) {
        [weakSelf.urls removeObject:url];
        NSHashTable* receivers = weakSelf.receivers;
        @synchronized (receivers) {
            for (NSObject <WLImageFetching> *receiver in receivers) {
                if ([receiver respondsToSelector:@selector(fetcherTargetUrl:)] && [[receiver fetcherTargetUrl:weakSelf] isEqualToString:url]) {
                    if ([receiver respondsToSelector:@selector(fetcher:didFinishWithImage:cached:)]) {
                        [receiver fetcher:weakSelf didFinishWithImage:image cached:cached];
                    }
                }
            }
        }
    };
    
    if ([[WLImageCache cache] containsImageWithUrl:url]) {
        [[WLImageCache cache] imageWithUrl:url completion:success];
    } else if (url.absolutePath) {
        [self setFileSystemUrl:url completion:success];
    } else {
        WLFailureBlock failure = ^ (NSError* error) {
            [weakSelf.urls removeObject:url];
            NSHashTable* receivers = weakSelf.receivers;
            @synchronized (receivers) {
                for (NSObject <WLImageFetching> *receiver in receivers) {
                    if ([receiver respondsToSelector:@selector(fetcherTargetUrl:)] && [[receiver fetcherTargetUrl:weakSelf] isEqualToString:url]) {
                        if ([receiver respondsToSelector:@selector(fetcher:didFailWithError:)]) {
                            [receiver fetcher:weakSelf didFailWithError:error];
                        }
                    }
                }
            }
        };
        [self setNetworkUrl:url success:success failure:failure];
    }
}

- (void)setNetworkUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [self imageResponseSerializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		[[WLImageCache cache] setImage:responseObject withUrl:url];
		if (success) success(responseObject, NO);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (error.code != NSURLErrorCancelled && failure) failure(error);
	}];
	[[self fetchingQueue] addOperation:operation];
}

- (void)setFileSystemUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
    if (!completion) return;
    UIImage* image = [WLSystemImageCache imageWithIdentifier:url];
    if (image) {
        completion(image, YES);
    } else {
        run_getting_object(^id{
            return [UIImage imageWithContentsOfFile:url];
        }, ^ (UIImage* image) {
            [WLSystemImageCache setImage:image withIdentifier:url];
            completion(image, NO);
        });
    }
}

@end
