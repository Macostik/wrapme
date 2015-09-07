//
//  WLrecordCell.h
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class WLAddressBookRecord, WLAddressBookRecordCell, WLAddressBookPhoneNumber;

typedef NS_ENUM(NSUInteger, WLAddressBookPhoneNumberState) {
    WLAddressBookPhoneNumberStateDefault,
    WLAddressBookPhoneNumberStateSelected,
    WLAddressBookPhoneNumberStateAdded
};

@protocol WLAddressBookRecordCellDelegate <NSObject>

- (void)recordCell:(WLAddressBookRecordCell*)cell didSelectPhoneNumber:(WLAddressBookPhoneNumber*)person;

- (WLAddressBookPhoneNumberState)recordCell:(WLAddressBookRecordCell*)cell phoneNumberState:(WLAddressBookPhoneNumber*)phoneNumber;

- (void)recordCellDidToggle:(WLAddressBookRecordCell*)cell;

@end

@interface WLAddressBookRecordCell : StreamReusableView

@property (nonatomic, weak) IBOutlet id <WLAddressBookRecordCellDelegate> delegate;

@property (nonatomic) WLAddressBookPhoneNumberState state;

@property (nonatomic) BOOL opened;

@end
