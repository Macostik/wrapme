//
//  WLAPIRequest+DefinedRequests.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLAPIRequest (DefinedRequests)

+ (instancetype)candy:(WLCandy*)candy;

+ (instancetype)deleteCandy:(WLCandy*)candy;

+ (instancetype)deleteComment:(WLComment*)comment;

+ (instancetype)deleteWrap:(WLWrap*)wrap;

+ (instancetype)leaveWrap:(WLWrap *)wrap;

@end
