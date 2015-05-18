//
//  WLContributorCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLButton.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet WLButton *resendInviteButton;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIView *slideView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slideViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet WLButton *slideMenuButton;
@property (weak, nonatomic) IBOutlet WLButton *resendInviteDoneButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *resendInviteSpinner;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;

@end

@implementation WLContributorCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSideMenu:)];
    swipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.slideMenuButton addGestureRecognizer:swipe];
    swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSideMenu:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.slideMenuButton addGestureRecognizer:swipe];
    self.resendInviteButton.titleLabel.numberOfLines = 2;
    [self.resendInviteButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    self.signUpView.layer.borderWidth = 1;
    self.signUpView.layer.borderColor = self.signUpView.textColor.CGColor;
}

- (void)setup:(WLUser*)user {
	NSString * userNameText = [user isCurrentUser] ? WLLS(@"You") : user.name;
	BOOL isCreator = [self.delegate contributorCell:self isCreator:user];
	self.nameLabel.text = isCreator ? [NSString stringWithFormat:WLLS(@"%@ (Owner)"), userNameText] : userNameText;
    
    self.phoneLabel.text = user.securePhones;
    self.avatarView.url = user.picture.small;
    
    if (self.slideViewConstraint.constant != 0) {
        self.slideViewConstraint.constant = 0;
        [self.slideView setNeedsLayout];
    }
    
    BOOL wrapContributedByCurrentUser = [self.delegate contributorCell:self isCreator:[WLUser currentUser]];
    if (wrapContributedByCurrentUser) {
        self.deletable = ![user isCurrentUser];
    } else {
        self.deletable = NO;
    }
}

- (void)setDeletable:(BOOL)deletable {
	_deletable = deletable;
    self.removeButton.hidden = !deletable;
    WLUser *user = self.entry;
    self.inviteLabel.hidden = self.resendInviteButton.hidden = !user.isInvited;
    self.removeButtonLeadingConstraint.constant = deletable ? 0 : -self.removeButton.width;
    [self.resendInviteSpinner stopAnimating];
    
    if (self.resendInviteButton.hidden) {
        self.signUpView.hidden = NO;
        self.resendInviteDoneButton.hidden = YES;
    } else {
        self.inviteLabel.text = [NSString stringWithFormat:@"Invite sent %@. Swipe to resend invite", user.invitedAt.timeAgoString];
        self.signUpView.hidden = YES;
        BOOL invited = [self.delegate contributorCell:self isInvitedContributor:user];
        [self setInvitedState:invited];
    }
    
    [self setMenuHidden:![self.delegate contributorCell:self showMenu:user] animated:NO];
    
    self.slideMenuButton.hidden = self.removeButton.hidden && self.resendInviteButton.hidden;
}

- (void)setInvitedState:(BOOL)invited {
    
    self.resendInviteDoneButton.hidden = !invited;
    [self.resendInviteButton setTitle:invited ? @"" : @"Resend\ninvite" forState:UIControlStateNormal];
    self.resendInviteButton.userInteractionEnabled = !invited;
  
}

- (IBAction)toggleSideMenu:(id)sender {
    [self setMenuHidden:self.slideViewConstraint.constant != 0 animated:YES];
    [self.delegate contributorCell:self didToggleMenu:self.entry];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    if (hidden) {
        self.slideViewConstraint.constant = 0;
    } else {
        self.slideViewConstraint.constant = (self.resendInviteButton.hidden ? 0 : self.resendInviteButton.width) + (self.removeButton.hidden ? 0 : self.removeButton.width);
    }
    if (animated) {
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.5 delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.removeButtonLeadingConstraint.constant = weakSelf.deletable ? 0 : -self.removeButton.width;
            [weakSelf layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    } else {
        [self layoutIfNeeded];
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.entry];
}

- (IBAction)resendInvite:(WLButton*)sender {
    [self.resendInviteSpinner startAnimating];
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [sender setTitle:@"" forState:UIControlStateNormal];
    [self.delegate contributorCell:self didInviteContributor:self.entry completionHandler:^(BOOL success) {
        [weakSelf.resendInviteSpinner stopAnimating];
        [weakSelf setInvitedState:success];
    }];
}

@end
