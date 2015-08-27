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

@property (strong, nonatomic) NSArray *cells;

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

- (void)awakeFromNib {
    [super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.removeMetrics.hiddenBlock = ^BOOL(StreamIndex *index) {
        return ![weakSelf.cells containsObject:weakSelf.removeMetrics.identifier];
    };
    self.resendMetrics.hiddenBlock = ^BOOL(StreamIndex *index) {
        return ![weakSelf.cells containsObject:weakSelf.resendMetrics.identifier];
    };
    self.spinnerMetrics.hiddenBlock = ^BOOL(StreamIndex *index) {
        return ![weakSelf.cells containsObject:weakSelf.spinnerMetrics.identifier];
    };
    self.resendDoneMetrics.hiddenBlock = ^BOOL(StreamIndex *index) {
        return ![weakSelf.cells containsObject:weakSelf.resendDoneMetrics.identifier];
    };
}

- (void)setup:(WLUser*)user {
	
    BOOL wrapContributedByCurrentUser = [self.delegate contributorCell:self isCreator:[WLUser currentUser]];
    if (wrapContributedByCurrentUser) {
        self.deletable = ![user isCurrentUser];
    } else {
        self.deletable = NO;
    }
    
    NSMutableArray *cells = [NSMutableArray array];
    
    if (self.deletable) {
        [cells addObject:@"WLContributorRemoveCell"];
    }
    self.canBeInvited = user.isInvited;
    
    if (self.canBeInvited) {
        BOOL invited = [self.delegate contributorCell:self isInvitedContributor:user];
        [cells addObject:invited ? @"WLContributorResendDoneCell" : @"WLContributorResendCell"];
    }
    
    self.cells = [cells copy];
    
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
    
    run_after_asap(^{
        [self setMenuHidden:![self.delegate contributorCell:self showMenu:user] animated:NO];
    });
}

- (void)setCells:(NSArray *)cells {
    _cells = cells;
    if (self.entry) {
        self.dataSource.layoutOffset = self.width;
        [self layoutIfNeeded];
        self.dataSource.items = @[self.entry];
    }
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
    self.cells = [self.cells replace:@"WLContributorResendCell" with:@"WLContributorSpinnerCell"];
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [self.delegate contributorCell:self didInviteContributor:self.entry completionHandler:^(BOOL success) {
        sender.userInteractionEnabled = NO;
        weakSelf.cells = [weakSelf.cells replace:@"WLContributorSpinnerCell" with:success ? @"WLContributorResendDoneCell" : @"WLContributorResendCell"];
    }];
}

@end
