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
    self.filePath = self.candy.picture.large;
    WLCandy* candy = self.candy;
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
        WLPicture* newPicture = candy.picture;
        [[WLImageCache cache] setImageAtPath:oldPicture.medium withUrl:newPicture.medium];
        [[WLImageCache cache] setImageAtPath:oldPicture.small withUrl:newPicture.small];
        [[WLImageCache cache] setImageAtPath:oldPicture.large withUrl:newPicture.large];
        candy.wrap.updatedAt = candy.updatedAt;
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
