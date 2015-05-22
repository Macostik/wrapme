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
    self.filePath = candy.editedPicture.original;
    [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
    candy.uploadIdentifier = GUID();
    [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLCandy* candy = self.candy;
    if (candy.wrap.valid) {
        WLPicture* oldPicture = [candy.editedPicture copy];
        candy.editedPicture = nil;
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
