
//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLStillPictureViewController.h"
#import "WLNavigationHelper.h"
#import "WLPhotosViewController.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "WLSegmentedControl.h"
#import "WLBasicDataSource.h"
#import "WLEntryPresenter.h"
#import "WLChatViewController.h"
#import "WLContributorsViewController.h"
#import "WLWhatsUpSet.h"
#import "UIView+LayoutHelper.h"
#import "WLMessagesCounter.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLPhotosViewControllerDelegate, WLWhatsUpSetBroadcastReceiver, WLMessagesCounterReceiver>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *candyCountLabel;
@property (weak, nonatomic) IBOutlet WLSegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIViewController *viewController;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

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
    if (!self.selectedSegment) {
        [self photosTabSelected:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.wrap.valid) {
        [self updateWrapData];
        [self updateMessageCouter];
        [self updateCandyCounter];
        [self viewShowed];
    }
}

- (void)viewShowed {
    if (self.selectedSegment != self.segmentedControl.selectedSegment) {
        [self.segmentedControl setSelectedSegment:self.selectedSegment];
        id segment = [self.segmentedControl controlForSegment:self.selectedSegment];
        [segment sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)updateWrapData {
    WLWrap *wrap = self.wrap;
    self.nameLabel.text = wrap.name;
    BOOL requiresFollowing = wrap.requiresFollowing;
    self.followButton.hidden = !requiresFollowing;
    self.segmentedControl.hidden = self.settingsButton.hidden = requiresFollowing;
}

- (void)updateMessageCouter {
    self.messageCountLabel.intValue = [[WLMessagesCounter instance] countForWrap:self.wrap];
    [[WLMessagesCounter instance] update:nil];
}

- (void)updateCandyCounter {
    self.candyCountLabel.intValue = [[WLWhatsUpSet sharedSet] unreadCandiesCountForWrap:self.wrap];
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didUpdateBlock = ^(WLWrap *wrap) {
            [weakSelf updateWrapData];
        };
        receiver.willDeleteBlock = ^(WLWrap *wrap) {
            if (weakSelf.viewAppeared) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                [WLToast showMessageForUnavailableWrap:wrap];
            }
        };
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        [receiver setDidAddBlock:^(WLCandy *candy) {
            if ([weakSelf isViewLoaded] && weakSelf.selectedSegment == WLSegmentControlStatePhotos) {
                [candy markAsRead];
            }
        }];
    }];
    
    [[WLWhatsUpSet sharedSet].broadcaster addReceiver:self];
    
    [[WLMessagesCounter instance] addReceiver:self];
}

- (IBAction)photosTabSelected:(id)sender {
    self.selectedSegment = WLSegmentControlStatePhotos;
    self.viewController = [self controllerForClass:[WLPhotosViewController class] badge:self.candyCountLabel];
}

- (IBAction)chatTabSelected:(id)sender {
    self.selectedSegment = WLSegmentControlStateChat;
    self.viewController = [self controllerForClass:[WLChatViewController class] badge:self.messageCountLabel];
    [self updateCandyCounter];
}

- (IBAction)friendsTabSelected:(id)sender {
    self.selectedSegment = WLSegmentControlStateFriend;
    self.viewController = [self controllerForClass:[WLContributorsViewController class] badge:nil];
    [self updateCandyCounter];
}

- (IBAction)follow:(id)sender {
    [[WLAPIRequest followWrap:self.wrap] send:^(id object) {
        
    } failure:^(NSError *error) {
        
    }];
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap ? : self.wrap;
    if (self.wrap != wrap) {
        self.view = nil;
        self.wrap = wrap;
    }
    [wrap uploadPictures:pictures];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - Custom animation

- (void)setViewController:(UIViewController *)viewController {
    if (_viewController) {
        [_viewController.view removeFromSuperview];
    }
    _viewController = viewController;
    [self.containerView addSubview:viewController.view];
    [self.containerView makeResizibleSubview:viewController.view];
}

- (WLWrapEmbeddedViewController *)controllerForClass:(Class)class badge:(WLBadgeLabel*)badge {
    WLWrapEmbeddedViewController *viewController = nil;
    for (WLWrapEmbeddedViewController *createdViewController in self.childViewControllers) {
        if ([createdViewController.class isEqual:class]) {
            viewController = createdViewController;
        }
    }
    if (viewController == nil) {
        viewController = [class instantiate:self.storyboard];
        viewController.wrap = self.wrap;
        viewController.delegate = self;
        viewController.view.frame = self.containerView.bounds;
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
    }
    
    viewController.badge = badge;
    
    return viewController;
}

// MARK: - WLPhotoViewControllerDelegate

- (void)photosViewControllerDidAddPhoto:(WLPhotosViewController *)controller {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPictureViewController];
    stillPictureViewController.wrap = self.wrap;
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    stillPictureViewController.startFromGallery = NO;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

// MARK: - WLWhatsUpSetBroadcastReceiver

- (void)whatsUpBroadcaster:(WLBroadcaster *)broadcaster updated:(WLWhatsUpSet *)set {
    [self updateCandyCounter];
}

// MARK: - WLMessagesCounterReceiver

- (void)counterDidChange:(WLMessagesCounter *)counter {
    if (self.selectedSegment != WLSegmentControlStateChat) {
        self.messageCountLabel.intValue = [counter countForWrap:self.wrap];
    }
}

@end
