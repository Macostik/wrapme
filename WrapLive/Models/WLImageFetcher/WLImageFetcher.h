//
//  WLImageFetcher.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

typedef void (^WLImageFetcherBlock)(UIImage*, BOOL, NSError*);

@class WLImageFetcher;

@protocol WLImageFetching <WLBroadcastReceiver>

- (NSString*)fetcherTargetUrl:(WLImageFetcher*)fetcher;

- (void)fetcher:(WLImageFetcher*)fetcher didFinishWithImage:(UIImage*)image cached:(BOOL)cached;

- (void)fetcher:(WLImageFetcher*)fetcher didFailWithError:(NSError*)error;

@end

@interface WLImageFetcher : WLBroadcaster

+ (instancetype)fetcher;

- (instancetype)initWithReceiver:(id<WLImageFetching>)receiver;

- (void)enqueueImageWithUrl:(NSString*)url;

- (void)addReceiver:(id<WLImageFetching>)receiver;

@end

@interface UIImageView (WLImageFetcher) <WLImageFetching>

@property (nonatomic) NSString* url;

- (void)setUrl:(NSString *)url completion:(WLImageFetcherBlock)completion;

@property (strong, nonatomic) WLImageFetcherBlock completionBlock;

@end
