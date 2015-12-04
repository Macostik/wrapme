//
//  WLEditViewController.h
//  meWrap
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLEditViewController : WLBaseViewController <EditSessionDelegate>

@property (strong, nonatomic) EditSession *editSession;

- (void)setupEditableUserInterface;

- (void)validate:(ObjectBlock)success failure:(FailureBlock)failure;

- (void)apply:(ObjectBlock)success failure:(FailureBlock)failure;

- (void)didCompleteDoneAction;

@end
