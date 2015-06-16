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
#import "UIView+QuatzCoreAnimations.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+Additions.h"
#import "AFURLResponseSerialization.h"
#import "AFHTTPRequestOperation.h"

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
        self.fetchingQueue = [[NSOperationQueue alloc] init];
        self.imageResponseSerializer = [AFImageResponseSerializer serializer];
    }
    return self;
}

- (void)enqueueImageWithUrl:(NSString *)url receiver:(id)receiver {
    [self.receivers addObject:receiver];
    [self enqueueImageWithUrl:url];
}

- (void)enqueueImageWithUrl:(NSString *)url {
    return [self enqueueImageWithUrl:url completionBlock:nil];
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

- (void)enqueueImageWithUrl:(NSString *)url operationBlock:(void (^)(id operation))operationBlock {
    [self enqueueImageWithUrl:url operationBlock:operationBlock completionBlock:nil];
}

- (void)enqueueImageWithUrl:(NSString *)url completionBlock:(WLImageBlock)completionBlock {
    [self enqueueImageWithUrl:url operationBlock:nil completionBlock:completionBlock];
}

- (void)enqueueImageWithUrl:(NSString *)url operationBlock:(void (^)(id operation))operationBlock completionBlock:(WLImageBlock)completionBlock {
    
    id operation = nil;
    
	if (!url.nonempty || [self.urls containsObject:url]) {
        if (operationBlock) {
            for (AFHTTPRequestOperation *_operation in self.fetchingQueue.operations) {
                if ([[_operation.request.URL absoluteString] isEqualToString:url]) {
                    operation = _operation;
                    break;
                }
            }
        }
        if (completionBlock) completionBlock(nil);
    } else {
        [self.urls addObject:url];
        __weak typeof(self)weakSelf = self;
        WLImageFetcherBlock success = ^(UIImage *image, BOOL cached) {
            [weakSelf handleResultForUrl:url block:^(NSObject<WLImageFetching> *receiver) {
                [receiver fetcher:weakSelf didFinishWithImage:image cached:cached];
            }];
            if (completionBlock) completionBlock(image);
        };
        
        if ([[WLImageCache cache] containsImageWithUrl:url]) {
            [[WLImageCache cache] imageWithUrl:url completion:success];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
            [self setFileSystemUrl:url completion:success];
        } else {
            operation = [self setNetworkUrl:url success:success failure:^(NSError *error) {
                [weakSelf handleResultForUrl:url block:^(NSObject<WLImageFetching> *receiver) {
                    [receiver fetcher:weakSelf didFailWithError:error];
                }];
                if (completionBlock) completionBlock(nil);
            }];
        }
    }
	
    if (operationBlock) {
        operationBlock(operation);
    }
}

- (id)setNetworkUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
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
    return operation;
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
