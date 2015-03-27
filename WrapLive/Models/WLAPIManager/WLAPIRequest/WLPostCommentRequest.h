//
//  WLPostCommentRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLPostCommentRequest : WLAPIRequest

@property (weak, nonatomic) WLComment* comment;

+ (instancetype)request:(WLComment*)comment;

@end
