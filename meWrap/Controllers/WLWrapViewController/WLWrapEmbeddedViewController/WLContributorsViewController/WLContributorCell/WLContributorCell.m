//
//  WLContributorCell.m
//  meWrap
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLButton.h"
#import "UIScrollView+Additions.h"

@interface WLContributorInnerCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet WLButton *slideMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;

@end

@implementation WLContributorInnerCell @end

@interface WLContributorCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSArray *cells;

@property (nonatomic) BOOL deletable;

@property (nonatomic) BOOL canBeInvited;

@end

@implementation WLContributorCell

- (void)setup:(WLUser*)user {
	
    BOOL wrapContributedByCurrentUser = [self.delegate contributorCell:self isCreator:[WLUser currentUser]];
    if (wrapContributedByCurrentUser) {
        self.deletable = ![user isCurrentUser];
    } else {
        self.deletable = NO;
    }
    
    NSMutableArray *cells = [NSMutableArray arrayWithObject:@"contributorInfo"];
    
    if (self.deletable) {
        [cells addObject:@"removeAction"];
    }
    self.canBeInvited = user.isInvited;
    
    if (self.canBeInvited) {
        BOOL invited = [self.delegate contributorCell:self isInvitedContributor:user];
        [cells addObject:invited ? @"resendDone" : @"resendInviteAction"];
    }
    
    self.cells = [cells copy];
    
    run_after_asap(^{
        [self setMenuHidden:![self.delegate contributorCell:self showMenu:user] animated:NO];
    });
}

- (void)setCells:(NSArray *)cells {
    _cells = cells;
    [self.collectionView reloadData];
}

- (IBAction)toggleSideMenu:(id)sender {
    [self setMenuHidden:self.collectionView.contentOffset.x != 0 animated:YES];
    [self.delegate contributorCell:self didToggleMenu:self.entry];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    if (hidden) {
        [self.collectionView setMinimumContentOffsetAnimated:animated];
    } else {
        [self.collectionView setMaximumContentOffsetAnimated:animated];
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.entry];
}

- (IBAction)resendInvite:(WLButton*)sender {
    self.cells = [self.cells replace:@"resendInviteAction" with:@"resendingSpinner"];
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [self.delegate contributorCell:self didInviteContributor:self.entry completionHandler:^(BOOL success) {
        sender.userInteractionEnabled = NO;
        weakSelf.cells = [weakSelf.cells replace:@"resendingSpinner" with:success ? @"resendDone" : @"resendInviteAction"];
    }];
}

// MARK: - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cells.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLContributorInnerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cells[indexPath.item] forIndexPath:indexPath];
    if (indexPath.item == 0) {
        WLUser *user = self.entry;
        BOOL isCreator = [self.delegate contributorCell:self isCreator:user];
        NSString * userNameText = [user isCurrentUser] ? WLLS(@"you") : user.name;
        cell.nameLabel.text = isCreator ? [NSString stringWithFormat:WLLS(@"formatted_owner"), userNameText] : userNameText;
        cell.phoneLabel.text = user.securePhones;
        
        cell.inviteLabel.hidden = !self.canBeInvited;
        cell.signUpView.hidden = self.canBeInvited;
        
        NSString *url = user.picture.small;
        if (!cell.signUpView.hidden && !url.nonempty) {
            cell.avatarView.defaultBackgroundColor = WLColors.orange;
        } else {
            cell.avatarView.defaultBackgroundColor = WLColors.grayLighter;
        }
        cell.avatarView.url = url;
        
        if (self.canBeInvited) {
            cell.inviteLabel.text = user.invitationHintText;
        }
        
        cell.slideMenuButton.hidden = !self.deletable && !self.canBeInvited;
        
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.item == 0) ? collectionView.size : CGSizeMake(76, collectionView.height);
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint maximumContentOffset = scrollView.maximumContentOffset;
    if (targetContentOffset->x > maximumContentOffset.x/2) {
        targetContentOffset->x = maximumContentOffset.x;
    } else {
        targetContentOffset->x = 0;
    }
}

@end
