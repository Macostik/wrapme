//
//  WLPostEditingUploadCandyRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 19/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPostEditingUploadCandyRequest.h"

@implementation WLPostEditingUploadCandyRequest

+ (NSString *)defaultMethod {
    return @"PUT";
}

+ (instancetype)request:(WLCandy *)candy {
    WLPostEditingUploadCandyRequest* request = [WLPostEditingUploadCandyRequest request];
    request.candy = candy;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies/%@/", self.candy.wrap.identifier, self.candy.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLCandy* candy = self.candy;
    self.filePath = candy.picture.original;
    [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
    candy.uploadIdentifier = GUID();
    [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    if (self.candy.wrap.valid) {
        WLCandy* candy = self.candy;
        WLPicture* oldPicture = [candy.picture copy];
        [candy API_setup:[response.data dictionaryForKey:WLCandyKey]];
        [oldPicture cacheForPicture:candy.picture];
        return candy;
    }
    return nil;
}

- (void)handleFailure:(NSError *)error {
    [super handleFailure:error];
    if ([error isError:WLErrorContentUnavaliable]) {
        [self.candy remove];
    }
}

@end
