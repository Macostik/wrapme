//
//  WLImageFetcher.h
//  meWrap
//
//  Created by Ravenpod on 24.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"
#import <UIKit/UIKit.h>

@class WLImageFetcher;

typedef void (^WLImageFetcherBlock)(UIImage* image, BOOL cached);

@protocol WLImageFetching

@optional
- (NSString*)fetcherTargetUrl:(WLImageFetcher*)fetcher;

- (void)fetcher:(WLImageFetcher*)fetcher didFinishWithImage:(UIImage*)image cached:(BOOL)cached;

- (void)fetcher:(WLImageFetcher*)fetcher didFailWithError:(NSError*)error;

@end

@interface WLImageFetcher : WLBroadcaster

+ (instancetype)defaultFetcher;

- (id)enqueueImageWithUrl:(NSString *)url;

- (id)enqueueImageWithUrl:(NSString*)url receiver:(id)receiver;

- (void)setFileSystemUrl:(NSString *)url completion:(WLImageFetcherBlock)completion;

@end
