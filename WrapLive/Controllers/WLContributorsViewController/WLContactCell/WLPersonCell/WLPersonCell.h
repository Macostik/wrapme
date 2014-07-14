//
//  WLPhoneCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLPersonCell;
@class WLPerson;

@protocol WLPersonCellDelegate <NSObject>

- (void)personCell:(WLPersonCell*)cell didSelectPerson:(WLPerson *)person;

@end

@interface WLPersonCell : WLItemCell

@property (nonatomic, weak) IBOutlet id <WLPersonCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@end
