//
//  WLInviteViewContraller.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 6/3/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLInviteViewController;
@class WLContact;

@protocol WLInviteViewControllerDelegate <NSObject>

- (NSError*)inviteViewController:(WLInviteViewController*)controller didInviteContact:(WLContact*)contact;

@end

@interface WLInviteViewController : WLBaseViewController

@property (weak, nonatomic) id <WLInviteViewControllerDelegate> delegate;

@end