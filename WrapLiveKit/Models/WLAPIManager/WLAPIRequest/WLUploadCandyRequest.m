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
    self.filePath = self.candy.picture.large;
    WLCandy* candy = self.candy;
    [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
	[parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
    WLComment *firstComment = [[candy.comments objectsWhere:@"uploading == nil"] lastObject];
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
        [candy API_setup:[response.data dictionaryForKey:WLCandyKey]];
        WLPicture* newPicture = candy.picture;
        [[WLImageCache cache] setImageAtPath:oldPicture.medium withUrl:newPicture.medium];
        [[WLImageCache cache] setImageAtPath:oldPicture.small withUrl:newPicture.small];
        [[WLImageCache cache] setImageAtPath:oldPicture.large withUrl:newPicture.large];
        if ([candy.comments match:^BOOL(WLComment *comment) {
            return comment.status == WLContributionStatusReady;
        }]) {
            [[WLUploadingQueue queueForEntriesOfClass:[WLComment class]] prepareAndStart];
        }
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
