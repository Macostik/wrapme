//
//  WLImageFetcher.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLImageView.h"

@class WLImageFetcher;

@protocol WLImageFetching

- (NSString*)fetcherTargetUrl:(WLImageFetcher*)fetcher;

- (void)fetcher:(WLImageFetcher*)fetcher didFinishWithImage:(UIImage*)image cached:(BOOL)cached;

- (void)fetcher:(WLImageFetcher*)fetcher didFailWithError:(NSError*)error;

@end

@interface WLImageFetcher : WLBroadcaster

+ (instancetype)fetcher;

- (instancetype)initWithReceiver:(id<WLImageFetching>)receiver;

- (void)enqueueImageWithUrl:(NSString*)url;

- (void)enqueueImageWithUrl:(NSString*)url completion:(WLImageBlock)completion;

- (void)addReceiver:(id<WLImageFetching>)receiver;

@end
