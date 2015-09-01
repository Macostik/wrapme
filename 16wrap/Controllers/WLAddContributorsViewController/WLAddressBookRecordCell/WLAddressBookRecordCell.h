//
//  WLContactCell.h
//  moji
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class WLAddressBookRecord, WLAddressBookRecordCell, WLAddressBookPhoneNumber;

typedef NS_ENUM(NSUInteger, WLContactCellState) {
    WLContactCellStateDefault,
    WLContactCellStateSelected,
    WLContactCellStateAdded
};

@protocol WLContactCellDelegate <NSObject>

- (void)contactCell:(WLAddressBookRecordCell*)cell didSelectPerson:(WLAddressBookPhoneNumber*)person;

- (WLContactCellState)contactCell:(WLAddressBookRecordCell*)cell phoneNumberState:(WLAddressBookPhoneNumber*)phoneNumber;

- (void)contactCellDidToggle:(WLAddressBookRecordCell*)cell;

@end

@interface WLAddressBookRecordCell : UITableViewCell

+ (instancetype)cellWithContact:(WLAddressBookRecord*)contact inTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath;

@property (nonatomic, weak) IBOutlet id <WLContactCellDelegate> delegate;

@property (nonatomic) WLContactCellState state;

@property (nonatomic) BOOL opened;

@property (strong, nonatomic) WLAddressBookRecord *record;

+ (NSString *)collectionPersonsStringFromContact:(WLAddressBookRecord *)contact;

@end
