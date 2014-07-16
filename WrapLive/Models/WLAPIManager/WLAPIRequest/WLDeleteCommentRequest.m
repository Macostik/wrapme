//
//  WLDeleteCommentRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDeleteCommentRequest.h"

@implementation WLDeleteCommentRequest

+ (NSString *)defaultMethod {
    return @"DELETE";
}

+ (instancetype)request:(WLComment *)comment {
    WLDeleteCommentRequest* request = [WLDeleteCommentRequest request];
    request.comment = comment;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies/%@/comments/%@", self.comment.candy.wrap.identifier, self.comment.candy.identifier, self.comment.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    [self.comment remove];
    return nil;
}

@end
