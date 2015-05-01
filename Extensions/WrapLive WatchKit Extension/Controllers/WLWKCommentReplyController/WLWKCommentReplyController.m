//
//  WLWKCommentReplyController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/22/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCommentReplyController.h"

@interface WLWKCommentReplyController ()

@property (weak, nonatomic) WLCandy* candy;

@end

@implementation WLWKCommentReplyController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.candy = context;
}

- (NSString *)presetsPropertyListName {
    return @"WLWKCommentReplyPresets";
}

- (void)handlePreset:(NSString *)preset success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self.candy uploadComment:preset success:^(WLComment *comment) {
        if (success) success();
    } failure:failure];
}

@end



