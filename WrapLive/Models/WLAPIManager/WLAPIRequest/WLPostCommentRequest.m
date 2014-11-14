//
//  WLPostCommentRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPostCommentRequest.h"
#import "WLEntryNotifier.h"

@implementation WLPostCommentRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(WLComment *)comment {
    WLPostCommentRequest* request = [WLPostCommentRequest request];
    request.comment = comment;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies/%@/comments", self.comment.candy.wrap.identifier, self.comment.candy.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLComment* comment = self.comment;
    [parameters trySetObject:comment.text forKey:@"message"];
    [parameters trySetObject:comment.uploadIdentifier forKey:@"upload_uid"];
    [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLComment* comment = self.comment;
    if (comment.candy.valid) {
        [comment API_setup:[response.data dictionaryForKey:@"comment"]];
        [comment.candy touch:comment.createdAt];
        return comment;
    }
    return nil;
}

@end
