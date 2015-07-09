//
//  WLUploadCandyRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadCandyRequest.h"
#import "WLImageCache.h"
#import "WLEntryNotifier.h"
#import "WLUploadingQueue.h"

@implementation WLUploadCandyRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(WLCandy *)candy {
    WLUploadCandyRequest* request = [WLUploadCandyRequest request];
    request.candy = candy;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies", self.candy.wrap.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLCandy* candy = self.candy;
    self.filePath = candy.picture.original;
    [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
	[parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
    WLComment *firstComment = [[candy.comments where:@"uploading == nil"] anyObject];
    if (firstComment) {
        [parameters trySetObject:firstComment.text forKey:@"message"];
        [parameters trySetObject:firstComment.uploadIdentifier forKey:@"message_upload_uid"];
    }
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    if (self.candy.wrap.valid) {
        WLCandy* candy = self.candy;
        WLPicture* oldPicture = [candy.picture copy];
        candy.editedPicture = nil;
        [candy API_setup:[response.data dictionaryForKey:WLCandyKey]];
        [oldPicture cacheForPicture:candy.picture];
        return candy;
    }
    return nil;
}

- (void)handleFailure:(NSError *)error {
    [super handleFailure:error];
    if ([error isError:WLErrorUploadFileNotFound]) {
        [self.candy remove];
    }
}

@end
