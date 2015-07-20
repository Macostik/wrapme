//
//  WLAPIRequest+DefinedRequests.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest+DefinedRequests.h"
#import "WLEntryNotifier.h"

@implementation WLAPIRequest (DefinedRequests)

+ (instancetype)candy:(WLCandy *)candy {
    WLAPIRequest *request = nil;
    if (candy.wrap) {
        request = [self GET:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier];
    } else {
        request = [self GET:@"entities/%@", candy.identifier];
    }
    return [[request map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        success(candy.valid ? [candy update:[response.data dictionaryForKey:WLCandyKey]] : nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteCandy:(WLCandy *)candy {
    return [[[self DELETE:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [candy remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteComment:(WLComment *)comment {
    WLAPIRequest *request = [WLAPIRequest DELETE:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.identifier, comment.candy.identifier, comment.identifier];
    return [request map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLCandy *candy = comment.candy;
        [comment remove];
        if (candy.valid) {
            candy.commentCount = [response.data[WLCommentCountKey] intValue];
        }
        success(nil);
    }];
}

+ (instancetype)deleteWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@", wrap.identifier] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)leaveWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@/leave", wrap.identifier] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

@end
