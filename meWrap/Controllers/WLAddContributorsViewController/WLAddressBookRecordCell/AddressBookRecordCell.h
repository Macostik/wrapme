//
//  WLrecordCell.h
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class AddressBookRecord, AddressBookRecordCell, AddressBookPhoneNumber;

typedef NS_ENUM(NSUInteger, AddressBookPhoneNumberState) {
    AddressBookPhoneNumberStateDefault,
    AddressBookPhoneNumberStateSelected,
    AddressBookPhoneNumberStateAdded
};

@protocol AddressBookRecordCellDelegate <NSObject>

- (void)recordCell:(AddressBookRecordCell*)cell didSelectPhoneNumber:(AddressBookPhoneNumber*)person;

- (AddressBookPhoneNumberState)recordCell:(AddressBookRecordCell*)cell phoneNumberState:(AddressBookPhoneNumber*)phoneNumber;

- (void)recordCellDidToggle:(AddressBookRecordCell*)cell;

@end

@interface AddressBookRecordCell : StreamReusableView

@property (nonatomic, weak) IBOutlet id <AddressBookRecordCellDelegate> delegate;

@property (nonatomic) AddressBookPhoneNumberState state;

@property (nonatomic) BOOL opened;

@end
