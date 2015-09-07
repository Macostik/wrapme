//
//  WLPhoneCell.h
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class WLAddressBookPhoneNumberCell;
@class WLAddressBookPhoneNumber;

@protocol WLAddressBookPhoneNumberCellDelegate <NSObject>

- (void)personCell:(WLAddressBookPhoneNumberCell*)cell didSelectPerson:(WLAddressBookPhoneNumber *)person;

@end

@interface WLAddressBookPhoneNumberCell : UITableViewCell

@property (nonatomic, weak) IBOutlet id <WLAddressBookPhoneNumberCellDelegate> delegate;

@property (strong, nonatomic) WLAddressBookPhoneNumber *phoneNumber;

@property (nonatomic) BOOL checked;

@end
