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
		WLImageFetcherBlock completion = ^(UIImage *image, BOOL cached, NSError* error) {
            NSHashTable* receivers = weakSelf.receivers;
            @synchronized (receivers) {
                if (error) {
                    for (NSObject <WLImageFetching> *receiver in receivers) {
                        if ([receiver respondsToSelector:@selector(fetcherTargetUrl:)] && [[receiver fetcherTargetUrl:weakSelf] isEqualToString:url]) {
                            if ([receiver respondsToSelector:@selector(fetcher:didFailWithError:)]) {
                                [receiver fetcher:weakSelf didFailWithError:error];
                            }
                        }
                    }
                } else {
                    for (NSObject <WLImageFetching> *receiver in receivers) {
                        if ([receiver respondsToSelector:@selector(fetcherTargetUrl:)] && [[receiver fetcherTargetUrl:weakSelf] isEqualToString:url]) {
                            if ([receiver respondsToSelector:@selector(fetcher:didFinishWithImage:cached:)]) {
                                [receiver fetcher:weakSelf didFinishWithImage:image cached:cached];
                            }
                        }
                    }
                }
            }
			[weakSelf.urls removeObject:url];
		};
		
		if ([[WLImageCache cache] containsImageWithUrl:url]) {
			[[WLImageCache cache] imageWithUrl:url completion:^(UIImage *image, BOOL cached) {
				completion(image, cached, nil);
			}];
		} else if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
			[self setFileSystemUrl:url completion:completion];
		} else {
			[self setNetworkUrl:url completion:completion];
		}
	}
}

- (void)setNetworkUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [[self class] imageResponseSerializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (completion) {
			completion(responseObject, NO, nil);
		}
		[[WLImageCache cache] setImage:responseObject withUrl:url];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (error.code != NSURLErrorCancelled) {
			if (completion) {
				completion(nil, NO, error);
			}
		}
	}];
	[[[self class] fetchingQueue] addOperation:operation];
}

- (void)setFileSystemUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
	if (completion) {
		__block UIImage* image = [WLSystemImageCache imageWithIdentifier:url];
		if (image) {
			completion(image, YES, nil);
		} else {
			run_getting_object(^id{
				image = [UIImage imageWithContentsOfFile:url];
				[WLSystemImageCache setImage:image withIdentifier:url];
				return image;
			}, ^ (UIImage* image) {
				completion(image, NO, nil);
			});
		}
	}
}

@end

@implementation UIImageView (WLImageFetcher)

@dynamic url;

- (void)setCompletionBlock:(WLImageFetcherBlock)completionBlock {
	[self setAssociatedObject:completionBlock forKey:"WLImageFetcher_completionBlock"];
}

- (WLImageFetcherBlock)completionBlock {
	return [self associatedObjectForKey:"WLImageFetcher_completionBlock"];
}

- (NSString *)url {
	return [self associatedObjectForKey:"WLImageFetcher_URL"];
}

- (void)setUrl:(NSString *)url {
	[self setUrl:url completion:nil];
}

- (void)setUrl:(NSString *)url completion:(WLImageFetcherBlock)completion {
	self.image = nil;
	[self setAssociatedObject:url forKey:"WLImageFetcher_URL"];
	self.completionBlock = completion;
	[[WLImageFetcher fetcher] addReceiver:self];
	[[WLImageFetcher fetcher] enqueueImageWithUrl:url];
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	if (animated) {
        CGFloat alpha = self.alpha;
		self.alpha = 0.0f;
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.33f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.alpha = alpha;
        } completion:^(BOOL finished) {
        }];
	}
	self.image = image;
}

#pragma mark - WLImageFetching

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
	return self.url;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
	[self setImage:image animated:!cached];
	WLImageFetcherBlock completionBlock = self.completionBlock;
	if (completionBlock) {
		completionBlock(image, cached, nil);
		self.completionBlock = nil;
	}
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
	WLImageFetcherBlock completionBlock = self.completionBlock;
	if (completionBlock) {
		completionBlock(nil, NO, error);
		self.completionBlock = nil;
	}
}

@end
