//
//  WLContributorCell.m
//  moji
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLButton.h"
#import "UIScrollView+Additions.h"
#import "StreamDataSource.h"

@interface WLContributorCell ()

@property (nonatomic) BOOL deletable;

@property (nonatomic) BOOL canBeInvited;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet WLButton *slideMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet StreamMetrics *removeMetrics;
@property (weak, nonatomic) IBOutlet StreamMetrics *resendMetrics;
@property (weak, nonatomic) IBOutlet StreamMetrics *spinnerMetrics;
@property (weak, nonatomic) IBOutlet StreamMetrics *resendDoneMetrics;

@end

@implementation WLContributorCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.removeMetrics.hidden = YES;
    self.resendMetrics.hidden = YES;
    self.resendDoneMetrics.hidden = YES;
    self.spinnerMetrics.hidden = YES;
}

- (void)setup:(WLUser*)user {
	
    BOOL wrapContributedByCurrentUser = [self.delegate contributorCell:self isCreator:[WLUser currentUser]];
    if (wrapContributedByCurrentUser) {
        self.deletable = ![user isCurrentUser];
    } else {
        self.deletable = NO;
    }
    
    if (self.deletable) {
        self.removeMetrics.hidden = NO;
    }
    self.canBeInvited = user.isInvited;
    
    if (self.canBeInvited) {
        BOOL invited = [self.delegate contributorCell:self isInvitedContributor:user];
        self.resendDoneMetrics.hidden = !invited;
        self.resendMetrics.hidden = invited;
    }
    
    [self layoutIfNeeded];
    self.dataSource.layoutOffset = self.width;
    self.dataSource.items = @[user];
    
    BOOL isCreator = [self.delegate contributorCell:self isCreator:user];
    NSString * userNameText = [user isCurrentUser] ? WLLS(@"you") : user.name;
    self.nameLabel.text = isCreator ? [NSString stringWithFormat:WLLS(@"formatted_owner"), userNameText] : userNameText;
    self.phoneLabel.text = user.securePhones;
    
    self.inviteLabel.hidden = !self.canBeInvited;
    self.signUpView.hidden = self.canBeInvited;
    
    NSString *url = user.picture.small;
    if (!self.signUpView.hidden && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = WLColors.orange;
    } else {
        self.avatarView.defaultBackgroundColor = WLColors.grayLighter;
    }
    self.avatarView.url = url;
    
    if (self.canBeInvited) {
        self.inviteLabel.text = user.invitationHintText;
    }
    
    self.slideMenuButton.hidden = !self.deletable && !self.canBeInvited;
    
    [self setMenuHidden:![self.delegate contributorCell:self showMenu:user] animated:NO];
}

- (IBAction)toggleSideMenu:(id)sender {
    [self setMenuHidden:self.dataSource.streamView.contentOffset.x != 0 animated:YES];
    [self.delegate contributorCell:self didToggleMenu:self.entry];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    if (hidden) {
        [self.dataSource.streamView setMinimumContentOffsetAnimated:animated];
    } else {
        [self.dataSource.streamView setMaximumContentOffsetAnimated:animated];
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.entry];
}

- (IBAction)resendInvite:(WLButton*)sender {
    self.resendMetrics.hidden = YES;
    self.spinnerMetrics.hidden = NO;
    [self.dataSource reload];
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [self.delegate contributorCell:self didInviteContributor:self.entry completionHandler:^(BOOL success) {
        sender.userInteractionEnabled = NO;
        weakSelf.resendMetrics.hidden = success;
        weakSelf.resendDoneMetrics.hidden = !success;
        weakSelf.spinnerMetrics.hidden = YES;
        [weakSelf.dataSource reload];
    }];
}

@end
