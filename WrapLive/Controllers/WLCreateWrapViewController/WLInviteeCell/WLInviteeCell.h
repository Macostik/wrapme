//
//  WLInviteeCell.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/19/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLInviteeCell;
@class WLPerson;

@protocol WLInviteeCellDelegate <NSObject>

- (void)inviteeCell:(WLInviteeCell*)cell didRemovePerson:(WLPerson*)person;

@end

@interface WLInviteeCell : WLItemCell

@property (nonatomic) BOOL deletable;

@property (nonatomic, weak) IBOutlet id <WLInviteeCellDelegate> delegate;

@end
