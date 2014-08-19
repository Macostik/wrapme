//
//  WLImageFetcher.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImageFetcher.h"
#import "WLImageCache.h"
#import "WLBlocks.h"
#import "WLSystemImageCache.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "UIView+QuatzCoreAnimations.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+Additions.h"

@interface WLImageFetcher ()

@property (strong, nonatomic) NSMutableArray* urls;

@end

@implementation WLImageFetcher

+ (instancetype)fetcher {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

+ (NSOperationQueue*)fetchingQueue {
    static NSOperationQueue* instance = nil;
    if (instance == nil) {
        instance = [[NSOperationQueue alloc] init];
		instance.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return instance;
}

+ (AFImageResponseSerializer*)imageResponseSerializer {
    static AFImageResponseSerializer* instance = nil;
    if (instance == nil) {
        instance = [AFImageResponseSerializer serializer];
    }
    return instance;
}

- (instancetype)initWithReceiver:(id<WLImageFetching>)receiver {
    return [super initWithReceiver:receiver];
}

- (void)addReceiver:(id<WLImageFetching>)receiver {
	[super addReceiver:receiver];
}

- (NSMutableArray *)urls {
	if (!_urls) {
		_urls = [NSMutableArray array];
	}
	return _urls;
}

- (void)enqueueImageWithUrl:(NSString *)url {
	if (!url.nonempty) {
		return;
	}
	
	if (![self.urls containsObject:url]) {
		[self.urls addObject:url];
		__weak typeof(self)weakSelf = self;
		WLImageFetcherBlock success = ^(UIImage *image, BOOL cached) {
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
			[weakSelf.urls removeObject:url];
		};
        
		if ([[WLImageCache cache] containsImageWithUrl:url]) {
			[[WLImageCache cache] imageWithUrl:url completion:success];
		} else if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
			[self setFileSystemUrl:url completion:success];
		} else {
            WLFailureBlock failure = ^ (NSError* error) {
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
}

- (void)setNetworkUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [[self class] imageResponseSerializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success) {
			success(responseObject, NO);
		}
		[[WLImageCache cache] setImage:responseObject withUrl:url];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (error.code != NSURLErrorCancelled) {
			if (failure) {
				failure(error);
			}
		}
	}];
	[[[self class] fetchingQueue] addOperation:operation];
}

- (void)setFileSystemUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
	if (completion) {
		__block UIImage* image = [WLSystemImageCache imageWithIdentifier:url];
		if (image) {
			completion(image, YES);
		} else {
			run_getting_object(^id{
				image = [UIImage imageWithContentsOfFile:url];
				[WLSystemImageCache setImage:image withIdentifier:url];
				return image;
			}, ^ (UIImage* image) {
				completion(image, NO);
			});
		}
	}
}

@end
