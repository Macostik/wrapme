//
//  WLBlockImageFetching.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBlockImageFetching.h"
#import "WLImageFetcher.h"
#import "NSString+Additions.h"

@interface WLBlockImageFetching () <WLImageFetching>

@property (strong, nonatomic) NSString *identifier;

@property (strong, nonatomic) NSString* url;

@property (strong, nonatomic) WLImageBlock success;

@property (strong, nonatomic) WLFailureBlock failure;

@end

@implementation WLBlockImageFetching

static NSMutableDictionary *fetchings = nil;

+ (instancetype)fetchingWithUrl:(NSString*)url {
    return [[self alloc] initWithUrl:url];
}

- (instancetype)initWithUrl:(NSString*)url {
    self = [self init];
    if (self) {
        self.url = url;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.identifier = GUID();
    }
    return self;
}

- (id)enqueue:(WLImageBlock)success failure:(WLFailureBlock)failure {
    if (!fetchings) {
        fetchings = [NSMutableDictionary dictionary];
    }
    fetchings[self.identifier] = self;
    self.success = success;
    self.failure = failure;
    return [[WLImageFetcher fetcher] enqueueImageWithUrl:self.url receiver:self];
}

// MARK: - WLImageFetching

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    if (self.failure) self.failure(error);
    self.success = nil;
    self.failure = nil;
    [fetchings removeObjectForKey:self.identifier];
}

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    if (self.success) self.success(image);
    self.success = nil;
    self.failure = nil;
    [fetchings removeObjectForKey:self.identifier];
}

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
    return self.url;
}

@end
