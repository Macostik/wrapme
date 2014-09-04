//
//  WLUploadCandyRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadCandyRequest.h"
#import "WLImageCache.h"
#import "WLWrapBroadcaster.h"

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
    [parameters trySetObject:candy.uploadIdentifier forKey:@"upload_uid"];
	if ([candy isMessage]) {
		[parameters trySetObject:candy.message forKey:@"chat_message"];
	} else {
        [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:@"contributed_at_in_epoch"];
    }
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLCandy* candy = self.candy;
    WLPicture* picture = [candy.picture copy];
    [candy API_setup:[response.data dictionaryForKey:@"candy"]];
    if ([candy isImage]) {
        [[WLImageCache cache] setImageAtPath:picture.medium withUrl:candy.picture.medium];
        [[WLImageCache cache] setImageAtPath:picture.small withUrl:candy.picture.small];
        [[WLImageCache cache] setImageAtPath:picture.large withUrl:candy.picture.large];
    }
    candy.wrap.updatedAt = candy.updatedAt;
    [candy broadcastChange];
    return candy;
}

@end
