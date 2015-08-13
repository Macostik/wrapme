//
//  WLEditViewController.h
//  moji
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLEditSession.h"

@interface WLEditViewController : WLBaseViewController <WLEditSessionDelegate>

@property (strong, nonatomic) WLEditSession *editSession;

- (void)setupEditableUserInterface;

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)didCompleteDoneAction;

@end
