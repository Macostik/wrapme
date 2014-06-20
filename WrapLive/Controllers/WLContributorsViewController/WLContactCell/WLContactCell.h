//
//  WLContactCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLContact;
@class WLContactCell;
@class WLPhone;

@protocol WLContactCellDelegate <NSObject>

- (void)contactCell:(WLContactCell*)cell didSelectPhone:(WLPhone*)phone;

- (BOOL)contactCell:(WLContactCell*)cell phoneSelected:(WLPhone*)phone;

- (void)contactCellDidToggle:(WLContactCell*)cell;

@end

@interface WLContactCell : WLItemCell

+ (instancetype)cellWithContact:(WLContact*)contact inTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath;

@property (nonatomic, weak) IBOutlet id <WLContactCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@property (nonatomic) BOOL opened;

@end
