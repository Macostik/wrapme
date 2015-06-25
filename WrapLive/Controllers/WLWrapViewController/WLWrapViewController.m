
//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLStillPictureViewController.h"
#import "WLEditWrapViewController.h"
#import "WLNavigationHelper.h"
#import "WLPhotosViewController.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "SegmentedControl.h"
#import "WLTapBarStoryboardTransition.h"
#import "WLBasicDataSource.h"
#import "WLEntryPresenter.h"
#import "WLChatViewController.h"

@interface WLWrapViewController ()  <WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *animatableConstraint;

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
        id segment = [self.segmentedControl controlForSegment:self.segmentedControl.selectedSegment];
        [segment sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateWrapData];
    [self updateNotificationCouter];
     self.cameraButton.hidden = NO;
    [self viewShowed];
}

- (void)viewShowed {
    if (self.selectedSegment != self.segmentedControl.selectedSegment) {
        [self.segmentedControl setSelectedSegment:self.selectedSegment];
        self.cameraButton.hidden = !(self.selectedSegment == WLSegmentControlStatePhotos);
        id segment = [self.segmentedControl controlForSegment:self.selectedSegment];
        [segment sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)updateWrapData {
    self.nameLabel.text = self.wrap.name;
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
}

// MARK: - User Actions

- (IBAction)addPhoto:(id)sender {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPictureViewController];
    stillPictureViewController.wrap = self.wrap;
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    stillPictureViewController.startFromGallery = NO;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didAddBlock = receiver.didUpdateBlock = ^(WLWrap *wrap) {
            [weakSelf updateWrapData];
        };
        receiver.willDeleteBlock = ^(WLWrap *wrap) {
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            [WLToast showMessageForUnavailableWrap:wrap];
        };
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        [receiver setDidAddBlock:^(WLCandy *candy) {
            if ([weakSelf isViewLoaded]) {
                [candy markAsRead];
            }
        }];
    }];
    
    [WLMessage notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didAddBlock = receiver.didDeleteBlock = ^(WLMessage *message) {
            if (self.segmentedControl.selectedSegment != WLSegmentControlStateChat) {
                [weakSelf updateNotificationCouter];
            }
        };
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

- (BOOL)segmentedControl:(SegmentedControl*)control shouldSelectSegment:(NSInteger)segment {
    self.cameraButton.hidden = !(segment == WLSegmentControlStatePhotos);
    return YES;
}

// MARK: - WLPhotoViewControllerDelegate

- (void)photosViewController:(WLPhotosViewController *)controller usedDataSource:(WLBasicDataSource *)dataSource {
    dataSource.animatableConstraints = [NSArray arrayWithObject:self.animatableConstraint];
}

// MARK: - WLChatViewControllerDelegate

- (void)chatViewController:(WLChatViewController *)controller resetUnreageMessageCounter:(BOOL)reset {
    self.messageCountLabel.intValue = reset ? 0 : [self.wrap unreadNotificationsMessageCount];
}

@end
