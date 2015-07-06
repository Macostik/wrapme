
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
#import "UIView+Extentions.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *candyCountLabel;
@property (weak, nonatomic) IBOutlet WLSegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableArray *controllersContainer;


@end

@implementation WLWrapViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addNotifyReceivers];
        self.controllersContainer = [NSMutableArray array];
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
    [self updateWrapData];
    [self updateNotificationCouter];
    [self viewShowed];
}

- (void)viewShowed {
    if (self.selectedSegment != self.segmentedControl.selectedSegment) {
        [self.segmentedControl setSelectedSegment:self.selectedSegment];
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
            if ([weakSelf isViewLoaded] && weakSelf.selectedSegment == WLSegmentControlStatePhotos) {
                [candy markAsRead];
            }
            weakSelf.candyCountLabel.intValue = [[WLWhatsUpSet sharedSet] unreadCandiesCountForWrap:weakSelf.wrap];
        }];
    }];
    
    [WLMessage notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didAddBlock = receiver.didDeleteBlock = ^(WLMessage *message) {
            if (weakSelf.segmentedControl.selectedSegment != WLSegmentControlStateChat) {
                [weakSelf updateNotificationCouter];
            }
        };
    }];
}

- (IBAction)photosTabSelected:(id)sender {
    self.candyCountLabel.intValue = 0;
    [self controllerForSelectedSegment:self.segmentedControl.selectedSegment];
}

- (IBAction)chatTabSeleced:(id)sender {
    self.messageCountLabel.intValue = 0;
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

- (BOOL)segmentedControl:(SegmentedControl*)control didSelectSegment:(NSInteger)segment {
    self.selectedSegment = segment;
    [self controllerForSelectedSegment:segment];
    return YES;
}

- (void)addViewContrtroller:(UIViewController *)controller {
    controller.view.frame = self.containerView.bounds;
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
}

- (void)bringControllerViewToFront:(UIViewController *)controller {
    for (UIView *subView in self.containerView.subviews) {
        if ([controller.view isEqual:subView]) {
            [subView removeFromSuperview];
        }
    }
    [self.containerView addSubview:controller.view];
    [self.containerView makeResizibleSubview:controller.view];
}

- (void)controllerForSelectedSegment:(NSInteger)segment {
    UIViewController *viewController = nil;
    switch (segment) {
        case WLSegmentControlStatePhotos:
            viewController = [self controllerForClass:[WLPhotosViewController class]];
            [(id)viewController setDelegate:self];
            break;
        case WLSegmentControlStateChat:
            viewController = [self controllerForClass:[WLChatViewController class]];
            break;
        case WLSegmentControlStateFriend:
            viewController = [self controllerForClass:[WLContributorsViewController class]];
            break;
    }
   
    [self bringControllerViewToFront:viewController];
}

- (UIViewController *)controllerForClass:(Class)class {
    UIViewController *viewController = nil;
    for (UIViewController *createdViewController in self.controllersContainer) {
        if ([createdViewController.class isEqual:class]) {
            viewController = createdViewController;
        }
    }
    if (viewController == nil) {
        viewController = [class instantiate:self.storyboard];
        [(id)viewController setWrap:self.wrap];
        [self.controllersContainer addObject:viewController];
        [self addViewContrtroller:viewController];
    }
    
    return viewController;
}

// MARK: - WLPhotoViewControllerDelegate

- (void)photosViewController:(WLPhotosViewController *)controller didTouchCameraButton:(UIButton *)sender {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPictureViewController];
    stillPictureViewController.wrap = self.wrap;
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    stillPictureViewController.startFromGallery = NO;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

@end
