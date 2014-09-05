//
//  WLContributorCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

@class WLContributorCell;
@class WLUser;

@protocol WLContributorCellDelegate <NSObject>

@optional
- (void)contributorCell:(WLContributorCell*)cell didRemoveContributor:(WLUser*)contributor;
- (BOOL)contributorCell:(WLContributorCell*)cell isCreator:(WLUser*)contributor;

@end

@interface WLContributorCell : WLEntryCell

@property (nonatomic, weak) IBOutlet id <WLContributorCellDelegate> delegate;

@property (nonatomic) BOOL deletable;

@end
