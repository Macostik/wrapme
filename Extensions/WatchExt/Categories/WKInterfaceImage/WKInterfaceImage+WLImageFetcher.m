//
//  WKInterfaceImage+WLImageFetcher.m
//  meWrap
//
//  Created by Ravenpod on 4/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WKInterfaceImage+WLImageFetcher.h"

@implementation WKInterfaceImage (WLImageFetcher)

- (void)setUrl:(NSString *)url {
    [self setAssociatedObject:url forKey:"WKInterfaceImage_WLImageFetcherURL"];
    if (url.nonempty) {
        [[WLImageFetcher defaultFetcher] enqueueImageWithUrl:url receiver:self];
    }
}

- (NSString *)url {
    return [self associatedObjectForKey:"WKInterfaceImage_WLImageFetcherURL"];
}

// MARK: - WLImageFetching

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setImage:image];
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setImage:nil];
}

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
    return self.url;
}

@end

@implementation WKInterfaceGroup (WLImageFetcher)

- (void)setUrl:(NSString *)url {
    [self setAssociatedObject:url forKey:"WKInterfaceImage_WLImageFetcherURL"];
    if (url.nonempty) {
        [[WLImageFetcher defaultFetcher] enqueueImageWithUrl:url receiver:self];
    }
}

- (NSString *)url {
    return [self associatedObjectForKey:"WKInterfaceImage_WLImageFetcherURL"];
}

// MARK: - WLImageFetching

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setBackgroundImage:image];
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setBackgroundImage:nil];
}

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
    return self.url;
}

@end
