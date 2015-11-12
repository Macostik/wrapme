//
//  WLContributorCell.m
//  meWrap
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLButton.h"
#import "WLImageView.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet WLButton *slideMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;

@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (strong, nonatomic) StreamDataSource *dataSource;
@property (strong, nonatomic) StreamMetrics *removeMetrics;
@property (strong, nonatomic) StreamMetrics *resendMetrics;
@property (strong, nonatomic) StreamMetrics *spinnerMetrics;
@property (strong, nonatomic) StreamMetrics *resendDoneMetrics;

@end

@implementation WLContributorCell

+ (NSString *)invitationHintText:(User*)user {
    NSDate *invitedAt = user.invitedAt;
    if (invitedAt) {
        return [NSString stringWithFormat:@"Invite sent %@. Swipe to resend invite", [invitedAt stringWithDateStyle:NSDateFormatterLongStyle]];
    } else {
        return @"Invite sent. Swipe to resend invite";
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = [[StreamDataSource alloc] initWithStreamView:self.streamView];
    self.removeMetrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLContributorRemoveCell" size:76]];
    self.resendMetrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLContributorResendCell" size:76]];
    self.spinnerMetrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLContributorSpinnerCell" size:76]];
    self.resendDoneMetrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLContributorResendDoneCell" size:76]];
    self.removeMetrics.nibOwner = self.resendMetrics.nibOwner = self.spinnerMetrics.nibOwner = self.resendDoneMetrics.nibOwner = self;
    self.removeMetrics.hidden = YES;
    self.resendMetrics.hidden = YES;
    self.resendDoneMetrics.hidden = YES;
    self.spinnerMetrics.hidden = YES;
}

- (void)didDequeue {
    [super didDequeue];
    self.removeMetrics.hidden = YES;
    self.resendMetrics.hidden = YES;
    self.resendDoneMetrics.hidden = YES;
    self.spinnerMetrics.hidden = YES;
}

- (void)setup:(User *)user {
	
    BOOL deletable = NO;
    BOOL wrapContributedByCurrentUser = [self.delegate contributorCell:self isCreator:[User currentUser]];
    if (wrapContributedByCurrentUser) {
        deletable = ![user current];
    } else {
        deletable = NO;
    }
    
    if (deletable) {
        self.removeMetrics.hidden = NO;
    }
    BOOL canBeInvited = user.isInvited;
    
    if (canBeInvited) {
        BOOL invited = [self.delegate contributorCell:self isInvitedContributor:user];
        self.resendDoneMetrics.hidden = !invited;
        self.resendMetrics.hidden = invited;
    }
    
    [self layoutIfNeeded];
    self.dataSource.layoutOffset = self.width;
    self.dataSource.items = @[user];
    
    BOOL isCreator = [self.delegate contributorCell:self isCreator:user];
    NSString * userNameText = [user current] ? @"you".ls : user.name;
    self.nameLabel.text = isCreator ? [NSString stringWithFormat:@"formatted_owner".ls, userNameText] : userNameText;
    self.phoneLabel.text = user.securePhones;
    
    self.inviteLabel.hidden = !canBeInvited;
    self.signUpView.hidden = canBeInvited;
    
    NSString *url = user.picture.small;
    if (!self.signUpView.hidden && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = WLColors.orange;
    } else {
        self.avatarView.defaultBackgroundColor = WLColors.grayLighter;
    }
    self.avatarView.url = url;
    
    if (canBeInvited) {
        self.inviteLabel.text = [WLContributorCell invitationHintText:user];
    }
    
    self.slideMenuButton.hidden = !deletable && !canBeInvited;
    
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
