//
//  WLContributorCell.m
//  meWrap
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorCell.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet ImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet Button *slideMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet UILabel *pandingLabel;

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
    if (user.isInvited) {
        return [NSString stringWithFormat:@"invite_status_swipe_to".ls, [invitedAt stringWithDateStyle:NSDateFormatterShortStyle]];
    } else {
        return @"signup_status".ls;
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
    self.pandingLabel.text = canBeInvited ? @"sign_up_pending".ls : @"";
    self.phoneLabel.text = user.securePhones;
    
    NSString *url = user.avatar.small;
    if (!canBeInvited && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = Color.orange;
    } else {
        self.avatarView.defaultBackgroundColor = Color.grayLighter;
    }
    self.avatarView.url = url;
    

    self.inviteLabel.text = [WLContributorCell invitationHintText:user];
    
    
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

- (IBAction)resendInvite:(Button *)sender {
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
