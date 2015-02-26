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
@class WLPerson;

@protocol WLContactCellDelegate <NSObject>

- (void)contactCell:(WLContactCell*)cell didSelectPerson:(WLPerson*)person;

- (BOOL)contactCell:(WLContactCell*)cell personSelected:(WLPerson*)person;

- (void)contactCellDidToggle:(WLContactCell*)cell;

@end

@interface WLContactCell : WLItemCell

+ (instancetype)cellWithContact:(WLAddressBookRecord*)contact inTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath;

@property (nonatomic, weak) IBOutlet id <WLContactCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@property (nonatomic) BOOL opened;

+ (NSString *)collectionPersonsStringFromContact:(WLAddressBookRecord *)contact;

@end
