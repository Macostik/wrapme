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

+ (instancetype)followWrap:(WLWrap *)wrap {
    return [[[self POST:@"wraps/%@/follow", wrap.identifier] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap notifyOnAddition:^(id object) {
            [wrap addContributorsObject:[WLUser currentUser]];
        }];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)unfollowWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@/unfollow", wrap.identifier] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap notifyOnDeleting:^(id object) {
            [[WLUser currentUser] removeWrap:wrap];
        }];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)postComment:(WLComment*)comment {
    return [[[self POST:@"wraps/%@/candies/%@/comments", comment.candy.wrap.identifier, comment.candy.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:comment.text forKey:@"message"];
        [parameters trySetObject:comment.uploadIdentifier forKey:@"upload_uid"];
        [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] map:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLCandy *candy = comment.candy;
        if (candy.valid) {
            [comment API_setup:[response.data dictionaryForKey:@"comment"]];
            [candy touch:comment.createdAt];
            int commentCount = [response.data[WLCommentCountKey] intValue];
            if (candy.commentCount < commentCount)
                candy.commentCount = commentCount;
            success(comment);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)resendConfirmation:(NSString*)email {
    return [[self POST:@"users/resend_confirmation"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:email forKey:WLEmailKey];
    }];
}

@end
