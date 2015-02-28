//
//  WLContactCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLAddressBookRecord;
@class WLContactCell;
@class WLAddressBookPhoneNumber;

typedef NS_ENUM(NSUInteger, WLContactCellState) {
    WLContactCellStateDefault,
    WLContactCellStateSelected,
    WLContactCellStateAdded
};

@protocol WLContactCellDelegate <NSObject>

- (void)contactCell:(WLContactCell*)cell didSelectPerson:(WLAddressBookPhoneNumber*)person;

- (WLContactCellState)contactCell:(WLContactCell*)cell phoneNumberState:(WLAddressBookPhoneNumber*)phoneNumber;

- (void)contactCellDidToggle:(WLContactCell*)cell;

@end

@interface WLContactCell : WLItemCell

+ (instancetype)cellWithContact:(WLAddressBookRecord*)contact inTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath;

@property (nonatomic, weak) IBOutlet id <WLContactCellDelegate> delegate;

@property (nonatomic) WLContactCellState state;

@property (nonatomic) BOOL opened;

+ (NSString *)collectionPersonsStringFromContact:(WLAddressBookRecord *)contact;

@end
