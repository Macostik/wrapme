//
//  WLEditViewController.h
//  WrapLive
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLShakeViewController.h"
#import "WLEditSession.h"
#import "WLBlocks.h"

@interface WLEditViewController : WLShakeViewController <WLEditSessionDelegate>

@property (strong, nonatomic) WLEditSession *editSession;

- (void)setupEditableUserInterface;

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
