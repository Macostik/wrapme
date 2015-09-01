//
//  WLFollowingViewController.m
//  moji
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLFollowingViewController.h"
#import "UIViewController+Container.h"
#import "WLButton.h"
#import "WLNavigationHelper.h"
#import "WLWrapStatusImageView.h"

@interface WLFollowingViewController ()

@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *laterButton;
@property (weak, nonatomic) IBOutlet WLWrapStatusImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation WLFollowingViewController

+ (void)followWrapIfNeeded:(WLWrap *)wrap performAction:(WLBlock)action {
    if (wrap.requiresFollowing) {
        WLFollowingViewController *controller = [WLFollowingViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
        controller.wrap = wrap;
        controller.actionBlock = action;
        [[UIWindow mainWindow].rootViewController addContainedViewController:controller animated:NO];
    } else {
        if (action) action();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateState];
}

- (void)updateState {
    BOOL requiresFollowing = self.wrap.requiresFollowing;
    self.followButton.hidden = self.laterButton.hidden = !requiresFollowing;
    self.closeButton.hidden = requiresFollowing;
    self.nameLabel.text = self.wrap.name;
    self.ownerLabel.text = self.wrap.contributor.name;
    self.imageView.url = self.wrap.picture.small;
    self.imageView.isFollowed = self.wrap.isPublic && self.wrap.isContributing;
    self.imageView.isOwner = [self.wrap.contributor isCurrentUser];
    self.messageLabel.text = requiresFollowing ? WLLS(@"follow_wrap_suggestion") : WLLS(@"followed_wrap_suggestion");
}

- (IBAction)close:(id)sender {
    if (self.actionBlock)  {
        self.actionBlock();
    }
    [self removeFromContainerAnimated:NO];
}

- (IBAction)later:(id)sender {
    [self removeFromContainerAnimated:NO];
}

- (IBAction)follow:(WLButton*)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest followWrap:self.wrap] send:^(id object) {
        [weakSelf updateState];
        sender.loading = NO;
    } failure:^(NSError *error) {
        sender.loading = NO;
        [error show];
    }];
}

@end
