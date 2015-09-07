//
//  WLInviteViewContraller.h
//  meWrap
//
//  Created by Ravenpod on 6/3/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLInviteViewController;
@class WLAddressBookRecord;

@protocol WLInviteViewControllerDelegate <NSObject>

- (void)inviteViewController:(WLInviteViewController*)controller didInviteContact:(WLAddressBookRecord*)contact;

@end

@interface WLInviteViewController : WLBaseViewController

@property (weak, nonatomic) id <WLInviteViewControllerDelegate> delegate;

@end