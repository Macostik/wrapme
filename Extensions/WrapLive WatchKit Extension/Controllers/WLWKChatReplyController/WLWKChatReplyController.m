//
//  WLWKChatReplyController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/22/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKChatReplyController.h"

@interface WLWKChatReplyController ()

@property (weak, nonatomic) WLWrap* wrap;

@end

@implementation WLWKChatReplyController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.wrap = context;
}

- (NSString *)presetsPropertyListName {
    return @"WLWKChatReplyPresets";
}

- (void)handlePreset:(NSString *)preset success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self.wrap uploadMessage:preset success:^(WLMessage *message) {
        if (success) success();
    } failure:failure];
}

@end



