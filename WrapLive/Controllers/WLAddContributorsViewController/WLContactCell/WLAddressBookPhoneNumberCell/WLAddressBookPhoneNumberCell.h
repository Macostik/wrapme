//
//  WLPhoneCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLAddressBookPhoneNumberCell;
@class WLAddressBookPhoneNumber;

@protocol WLAddressBookPhoneNumberCellDelegate <NSObject>

- (void)personCell:(WLAddressBookPhoneNumberCell*)cell didSelectPerson:(WLAddressBookPhoneNumber *)person;

@end

@interface WLAddressBookPhoneNumberCell : WLItemCell

@property (nonatomic, weak) IBOutlet id <WLAddressBookPhoneNumberCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@end
