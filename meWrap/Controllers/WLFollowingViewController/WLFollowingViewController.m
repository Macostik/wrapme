//
//  WLFollowingViewController.m
//  meWrap
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLFollowingViewController.h"
#import "WLButton.h"

@interface WLFollowingViewController ()

@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *laterButton;
@property (weak, nonatomic) IBOutlet WrapCoverView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (strong, nonatomic) UIWindow* window;

@end

@implementation WLFollowingViewController

+ (void)followWrapIfNeeded:(Wrap *)wrap performAction:(Block)action {
    if (wrap.requiresFollowing) {
        WLFollowingViewController *controller = [UIStoryboard main][@"WLFollowingViewController"];
        controller.wrap = wrap;
        controller.actionBlock = action;
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.rootViewController = controller;
        [window makeKeyAndVisible];
        controller.window = window;
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
    self.imageView.url = self.wrap.asset.small;
    self.imageView.isFollowed = self.wrap.isPublic && self.wrap.isContributing;
    self.imageView.isOwner = [self.wrap.contributor current];
    self.messageLabel.text = (requiresFollowing ? @"follow_wrap_suggestion" : @"followed_wrap_suggestion").ls;
}

- (IBAction)close:(id)sender {
    if (self.actionBlock)  {
        self.actionBlock();
    }
    self.window.rootViewController = nil;
    self.window.hidden = YES;
}

- (IBAction)later:(id)sender {
    self.window.rootViewController = nil;
    self.window.hidden = YES;
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
