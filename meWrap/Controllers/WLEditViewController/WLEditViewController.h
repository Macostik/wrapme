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

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)didCompleteDoneAction;

@end
