//
//  WLWrapViewController.m
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLStillPictureViewController.h"
#import "WLMediaViewController.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "SegmentedControl.h"
#import "WLChatViewController.h"
#import "WLContributorsViewController.h"
#import "WLWhatsUpSet.h"
#import "WLMessagesCounter.h"
#import "WLButton.h"
#import "WLWrapStatusImageView.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLFollowingViewController.h"
#import "WLSoundPlayer.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLMediaViewControllerDelegate, WLWhatsUpSetBroadcastReceiver, WLMessagesCounterReceiver>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *candyCountLabel;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIViewController *viewController;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *unfollowButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *publicWrapView;
@property (weak, nonatomic) IBOutlet WLWrapStatusImageView *publicWrapImageView;
@property (weak, nonatomic) IBOutlet UILabel *creatorName;
@property (weak, nonatomic) IBOutlet UILabel *publicWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerDescriptionLabel;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *publicWrapPrioritizer;

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
    [super viewDidLoad];
    
    if (!self.wrap.valid) {
        return;
    }
    
    [self.segmentedControl deselect];
    
    self.settingsButton.exclusiveTouch = self.followButton.exclusiveTouch = self.unfollowButton.exclusiveTouch = YES;
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
        BOOL contributorIsCurrent = wrap.contributor.current;
        self.publicWrapImageView.url = wrap.contributor.picture.small;
        self.publicWrapImageView.isFollowed = wrap.isContributing;
        self.publicWrapImageView.isOwner = contributorIsCurrent;
        self.creatorName.text = wrap.contributor.name;
        BOOL requiresFollowing = wrap.requiresFollowing;
        self.segmentedControl.hidden = YES;
        self.settingsButton.hidden = requiresFollowing;
        self.publicWrapView.hidden = NO;
        self.followButton.hidden = !requiresFollowing || contributorIsCurrent;
        self.unfollowButton.hidden = requiresFollowing || contributorIsCurrent;
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
    self.messageCountLabel.value = [[WLMessagesCounter instance] countForWrap:self.wrap];
    [[WLMessagesCounter instance] update:nil];
}

- (void)updateCandyCounter {
    self.candyCountLabel.value = [[WLWhatsUpSet sharedSet] unreadCandiesCountForWrap:self.wrap];
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [[Wrap notifyReceiver:self] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setEntry:^Entry *{
            return weakSelf.wrap;
        }];
        receiver.didUpdate = ^(Entry *entry) {
            [weakSelf updateWrapData];
        };
        receiver.willDelete = ^(Entry *entry) {
            if (weakSelf.viewAppeared) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                [WLToast showMessageForUnavailableWrap:(Wrap*)entry];
            }
        };
    }];
    
    [[Candy notifyReceiver:self] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setContainer:^Entry *{
            return weakSelf.wrap;
        }];
        [receiver setDidAdd:^(Entry *entry) {
            if ([weakSelf isViewLoaded] && weakSelf.segment == WLWrapSegmentMedia) {
                [entry markAsRead];
            }
        }];
    }];
    
    [[WLWhatsUpSet sharedSet].broadcaster addReceiver:self];
    
    [[WLMessagesCounter instance] addReceiver:self];
}

- (IBAction)segmentChanged:(SegmentedControl*)sender {
    NSUInteger selectedSegment = self.segment = sender.selectedSegment;
    if (selectedSegment == WLWrapSegmentMedia) {
        self.viewController = [self controllerForClass:[WLMediaViewController class] badge:self.candyCountLabel];
    } else if (selectedSegment == WLWrapSegmentChat) {
        self.viewController = [self controllerForClass:[WLChatViewController class] badge:self.messageCountLabel];
    } else {
        self.viewController = [self controllerForClass:[WLContributorsViewController class] badge:nil];
    }
    [self updateCandyCounter];
}

- (IBAction)follow:(WLButton*)sender {
    sender.loading = YES;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        [[WLAPIRequest followWrap:self.wrap] send:^(id object) {
            sender.loading = NO;
            [operation finish];
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
            [operation finish];
        }];
    });
}

- (IBAction)unfollow:(WLButton*)sender {
    self.settingsButton.userInteractionEnabled = NO;
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        [[WLAPIRequest unfollowWrap:self.wrap] send:^(id object) {
            sender.loading = NO;
            weakSelf.settingsButton.userInteractionEnabled = YES;
            [operation finish];
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
            weakSelf.settingsButton.userInteractionEnabled = YES;
            [operation finish];
        }];
    });
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
    
    [WLFollowingViewController followWrapIfNeeded:wrap performAction:^{
        [WLSoundPlayer playSound:WLSound_s04];
        [wrap uploadPictures:pictures];
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

- (WLWrapEmbeddedViewController *)controllerForClass:(Class)class badge:(WLBadgeLabel*)badge {
    WLWrapEmbeddedViewController *viewController = [self.childViewControllers select:^BOOL(WLWrapEmbeddedViewController *controller) {
        return controller.class == class;
    }];
    if (viewController == nil) {
        viewController = self.storyboard[NSStringFromClass(class)];
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

- (void)mediaViewControllerDidAddPhoto:(WLMediaViewController *)controller {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPhotosViewController];
    stillPictureViewController.wrap = self.wrap;
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    stillPictureViewController.startFromGallery = NO;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

- (void)mediaViewControllerDidOpenLiveBroadcast:(WLMediaViewController *)controller {
    LiveBroadcastViewController *liveBroadcastController = self.storyboard[@"liveBroadcast"];
    liveBroadcastController.wrap = self.wrap;
    [self.navigationController presentViewController:liveBroadcastController animated:NO completion:nil];
}

// MARK: - WLWhatsUpSetBroadcastReceiver

- (void)whatsUpBroadcaster:(WLBroadcaster *)broadcaster updated:(WLWhatsUpSet *)set {
    [self updateCandyCounter];
}

// MARK: - WLMessagesCounterReceiver

- (void)counterDidChange:(WLMessagesCounter *)counter {
    if (self.segment != WLWrapSegmentChat) {
        self.messageCountLabel.value = [counter countForWrap:self.wrap];
    }
}

@end
