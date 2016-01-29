//
//  WLWrapViewController.m
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLStillPictureViewController.h"
#import "WLChatViewController.h"
#import "WLContributorsViewController.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, MediaViewControllerDelegate, RecentUpdateListNotifying>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet BadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet BadgeLabel *candyCountLabel;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIViewController *viewController;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *unfollowButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *publicWrapView;
@property (weak, nonatomic) IBOutlet WrapCoverView *publicWrapImageView;
@property (weak, nonatomic) IBOutlet UILabel *creatorName;
@property (weak, nonatomic) IBOutlet UILabel *publicWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerDescriptionLabel;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *publicWrapPrioritizer;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *titleViewPrioritizer;
@property (weak, nonatomic) IBOutlet Label *typingLabel;

@property (strong, nonatomic) EntryNotifyReceiver *wrapNotifyReceiver;

@property (strong, nonatomic) EntryNotifyReceiver *candyNotifyReceiver;

@end

@implementation WLWrapViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addNotifyReceivers];
    }
    return self;
}

- (void)viewDidLoad {
    __weak __typeof(self)weakSelf = self;
    [super viewDidLoad];
    
    if (!self.wrap.valid) {
        return;
    }
    
    WLWrapEmbeddedViewController *chatViewController = [self controllerNamed:@"chat" badge:self.messageCountLabel];
    if (chatViewController.view) {
        chatViewController.typingHalper = ^(NSString *text) {
            weakSelf.titleViewPrioritizer.defaultState = !text.nonempty;
            weakSelf.typingLabel.text = text;
        };
    }
    [self.segmentedControl deselect];
    
    self.settingsButton.exclusiveTouch = self.followButton.exclusiveTouch = self.unfollowButton.exclusiveTouch = YES;
}

- (void)presentLiveProadcast:(LiveBroadcast *)broadcast {
    if (self.segment != WLWrapSegmentMedia) {
        [self changeSegment:WLWrapSegmentMedia];
    }
    MediaViewController *controller = (id)[self controllerNamed:@"media" badge:self.candyCountLabel];
    [controller presentLiveBroadcast:broadcast];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.wrap.valid) {
        [self updateWrapData];
        [self updateSegmentIfNeeded];
        [self updateMessageCouter];
    }
}

- (void)updateSegmentIfNeeded {
    if (self.segment != self.segmentedControl.selectedSegment) {
        self.segmentedControl.selectedSegment = self.segment;
        [self segmentChanged:self.segmentedControl];
    }
}

- (void)updateWrapData {
    Wrap *wrap = self.wrap;
    self.nameLabel.text = wrap.name;
    if (wrap.isPublic) {
        [self followingStateForWrap:self.wrap];
        BOOL contributorIsCurrent = wrap.contributor.current;
        self.publicWrapImageView.url = wrap.contributor.avatar.small;
        self.publicWrapImageView.isFollowed = wrap.isContributing;
        self.publicWrapImageView.isOwner = contributorIsCurrent;
        self.creatorName.text = wrap.contributor.name;
        BOOL requiresFollowing = wrap.requiresFollowing;
        self.segmentedControl.hidden = YES;
        self.settingsButton.hidden = requiresFollowing;
        self.publicWrapView.hidden = NO;
        self.publicWrapPrioritizer.defaultState = YES;
        self.publicWrapNameLabel.text = wrap.name;
        self.ownerDescriptionLabel.hidden = !contributorIsCurrent;
    } else {
        self.segmentedControl.hidden = NO;
        self.settingsButton.hidden = NO;
        self.publicWrapView.hidden = YES;
        self.publicWrapPrioritizer.defaultState = NO;
    }
}

- (void)updateMessageCouter {
    self.messageCountLabel.value = self.wrap.numberOfUnreadMessages;
}

- (void)updateCandyCounter {
    self.candyCountLabel.value = [[RecentUpdateList sharedList] unreadCandiesCountForWrap:self.wrap];
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    self.wrapNotifyReceiver = [[Wrap notifyReceiver] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setEntry:^Entry *{
            return weakSelf.wrap;
        }];
        receiver.didUpdate = ^(Entry *entry, EntryUpdateEvent event) {
            if (event == EntryUpdateEventNumberOfUnreadMessagesChanged) {
                if (weakSelf.segment != WLWrapSegmentChat) {
                    weakSelf.messageCountLabel.value = weakSelf.wrap.numberOfUnreadMessages;
                }
            } else {
                [weakSelf updateWrapData];
            }
        };
        receiver.willDelete = ^(Entry *entry) {
            if (weakSelf.viewAppeared) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                [Toast showMessageForUnavailableWrap:(Wrap*)entry];
            }
        };
    }];
    
    self.candyNotifyReceiver = [[Candy notifyReceiver] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setContainer:^Entry *{
            return weakSelf.wrap;
        }];
        [receiver setDidAdd:^(Entry *entry) {
            if ([weakSelf isViewLoaded] && weakSelf.segment == WLWrapSegmentMedia) {
                [entry markAsUnread:NO];
            }
        }];
    }];
    
    [[RecentUpdateList sharedList] addReceiver:self];
}

- (void)changeSegment:(WLWrapSegment)segment {
    self.segment = segment;
    if (segment == WLWrapSegmentMedia) {
        self.viewController = [self controllerNamed:@"media" badge:self.candyCountLabel];
    } else if (segment == WLWrapSegmentChat) {
        self.viewController = [self controllerNamed:@"chat" badge:self.messageCountLabel];
    } else {
        self.viewController = [self controllerNamed:@"friends" badge:nil];
    }
    [self updateCandyCounter];
}

- (IBAction)segmentChanged:(SegmentedControl*)sender {
    [self changeSegment:sender.selectedSegment];
}

- (IBAction)follow:(Button *)sender {
    sender.loading = YES;
    __weak __typeof(self)weakSelf = self;
    [[RunQueue fetchQueue] run:^(Block finish) {
        [[APIRequest followWrap:self.wrap] send:^(id object) {
            sender.loading = NO;
            [weakSelf followingStateForWrap:weakSelf.wrap];
            finish();
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
            finish();
        }];
    }];
}

- (IBAction)unfollow:(Button *)sender {
    self.settingsButton.userInteractionEnabled = NO;
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [[RunQueue fetchQueue] run:^(Block finish) {
        [[APIRequest unfollowWrap:self.wrap] send:^(id object) {
            sender.loading = NO;
            weakSelf.settingsButton.userInteractionEnabled = YES;
            [weakSelf followingStateForWrap:weakSelf.wrap];
            finish();
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
            weakSelf.settingsButton.userInteractionEnabled = YES;
            finish();
        }];
    }];
}

- (void)followingStateForWrap:(Wrap *)wrap {
    self.followButton.hidden = !wrap.requiresFollowing || wrap.contributor.current;
    self.unfollowButton.hidden = !self.followButton.hidden;
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    
    Wrap *wrap = controller.wrap ? : self.wrap;
    if (self.wrap != wrap) {
        self.view = nil;
        self.viewController = nil;
        for (UIViewController *controller in [self.childViewControllers copy]) {
            if ([controller isKindOfClass:[WLWrapEmbeddedViewController class]]) {
                [controller removeFromParentViewController];
            }
        }
        self.wrap = wrap;
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [FollowingViewController followWrapIfNeeded:wrap performAction:^{
        [[SoundPlayer player] play:Sounds04];
        [wrap uploadAssets:pictures];
    }];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - Custom animation

- (void)setShowKeyboard:(BOOL)showKeyboard {
    _showKeyboard = showKeyboard;
    if (self.segment == WLWrapSegmentChat && showKeyboard) {
        WLChatViewController *viewController = (id)_viewController;
        viewController.showKeyboard = showKeyboard;
        if ([viewController isViewLoaded]) {
            _showKeyboard = NO;
        }
    }
}

- (void)setViewController:(UIViewController *)viewController {
    if (_viewController) {
        [_viewController.view removeFromSuperview];
    }
    _viewController = viewController;
    if (viewController) {
        if (self.segment == WLWrapSegmentChat) {
            WLChatViewController *viewController = (id)_viewController;
            viewController.showKeyboard = self.showKeyboard;
            self.showKeyboard = NO;
        }
        
        UIView *view = viewController.view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.frame = self.containerView.bounds;
        [self.containerView addSubview:view];
        [self.containerView makeResizibleSubview:view];
        [self.view setNeedsLayout];
    }
}

- (WLWrapEmbeddedViewController *)controllerNamed:(NSString*)name badge:(BadgeLabel*)badge {
    WLWrapEmbeddedViewController *viewController = [self.childViewControllers selectObject:^BOOL(WLWrapEmbeddedViewController *controller) {
        return [controller.restorationIdentifier isEqualToString:name];
    }];
    if (viewController == nil) {
        viewController = (id)self.storyboard[name];
        viewController.preferredViewFrame = self.containerView.bounds;
        viewController.wrap = self.wrap;
        viewController.delegate = self;
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
    }
    
    viewController.badge = badge;
    
    return viewController;
}

// MARK: - WLMediaViewControllerDelegate

- (void)mediaViewControllerDidAddPhoto:(MediaViewController *)controller {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPhotosViewController:self.wrap];
    stillPictureViewController.delegate = self;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

// MARK: - RecentUpdateListNotifying

- (void)recentUpdateListUpdated:(RecentUpdateList *)list {
    [self updateCandyCounter];
    [self updateMessageCouter];
}

@end
