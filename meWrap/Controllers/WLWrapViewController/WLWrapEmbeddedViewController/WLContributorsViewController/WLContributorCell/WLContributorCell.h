//
//  WLContributorCell.h
//  meWrap
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class WLContributorCell;
@class WLUser;

@protocol WLContributorCellDelegate <NSObject>

- (void)contributorCell:(WLContributorCell*)cell didRemoveContributor:(User *)contributor;
- (void)contributorCell:(WLContributorCell*)cell didInviteContributor:(User *)contributor completionHandler:(void (^)(BOOL))completionHandler;
- (BOOL)contributorCell:(WLContributorCell*)cell isInvitedContributor:(User *)contributor;
- (BOOL)contributorCell:(WLContributorCell*)cell isCreator:(User *)contributor;
- (void)contributorCell:(WLContributorCell*)cell didToggleMenu:(User *)contributor;
- (BOOL)contributorCell:(WLContributorCell*)cell showMenu:(User *)contributor;

@end

@interface WLContributorCell : StreamReusableView

@property (nonatomic, weak) IBOutlet id <WLContributorCellDelegate> delegate;

+ (NSString *)invitationHintText:(User*)user;

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated;

@end
