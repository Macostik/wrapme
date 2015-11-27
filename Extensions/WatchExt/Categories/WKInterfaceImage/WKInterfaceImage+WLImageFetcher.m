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
        [[ImageFetcher defaultFetcher] enqueue:url receiver:self];
    }
}

- (NSString *)url {
    return [self associatedObjectForKey:"WKInterfaceImage_WLImageFetcherURL"];
}

// MARK: - WLImageFetching

- (void)fetcher:(ImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setImage:image];
}

- (void)fetcher:(ImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setImage:nil];
}

- (NSString *)fetcherTargetUrl:(ImageFetcher *)fetcher {
    return self.url;
}

@end

@implementation WKInterfaceGroup (WLImageFetcher)

- (void)setUrl:(NSString *)url {
    [self setAssociatedObject:url forKey:"WKInterfaceImage_WLImageFetcherURL"];
    if (url.nonempty) {
        [[ImageFetcher defaultFetcher] enqueue:url receiver:self];
    }
}

- (NSString *)url {
    return [self associatedObjectForKey:"WKInterfaceImage_WLImageFetcherURL"];
}

// MARK: - WLImageFetching

- (void)fetcher:(ImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [self setBackgroundImage:image];
}

- (void)fetcher:(ImageFetcher *)fetcher didFailWithError:(NSError *)error {
    [self setBackgroundImage:nil];
}

- (NSString *)fetcherTargetUrl:(ImageFetcher *)fetcher {
    return self.url;
}

@end
