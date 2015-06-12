
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
#import "WLPickerViewController.h"
#import "WLCreateWrapViewController.h"
#import "WLNavigationHelper.h"
#import "WLPhotosViewController.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "SegmentedControl.h"

@interface WLWrapViewController ()  <WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;

@end

@implementation WLWrapViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addNotifyReceivers];
        [[WLNetwork network] addReceiver:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.wrap.valid) {
        return;
    }
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    id segment = [self.segmentedControl controlForSegment:self.segmentedControl.selectedSegment];
    [segment sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateWrapData];
    [self updateNotificationCouter];
     self.cameraButton.hidden = NO;
}

- (void)updateWrapData {
    self.nameLabel.text = self.wrap.name;
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
}

- (UIViewController *)shakePresentedViewController {
    WLStillPictureViewController *controller = [WLStillPictureViewController instantiate:
                                                [UIStoryboard storyboardNamed:WLCameraStoryboard]];
    controller.wrap = self.wrap;
    controller.delegate = self;
    controller.mode = WLStillPictureModeDefault;
    return controller;
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
            [weakSelf updateNotificationCouter];
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
//    [self.collectionView setMinimumContentOffsetAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didSelectWrap:(WLWrap *)wrap {
    WLPickerViewController *pickerViewController = [[WLPickerViewController alloc] initWithWrap:wrap delegate:self];
    [controller presentViewController:pickerViewController animated:NO completion:nil];
}

// MARK: - WLPickerViewDelegate

- (void)pickerViewControllerNewWrapClicked:(WLPickerViewController *)pickerViewController {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    [stillPictureViewController dismissViewControllerAnimated:YES completion:^{
        WLCreateWrapViewController *createWrapViewController = [WLCreateWrapViewController new];
        [createWrapViewController setCreateHandler:^(WLWrap *wrap) {
            stillPictureViewController.wrap = wrap;
            [stillPictureViewController dismissViewControllerAnimated:NO completion:NULL];
        }];
        [createWrapViewController setCancelHandler:^{
            [stillPictureViewController dismissViewControllerAnimated:NO completion:NULL];
        }];
        [stillPictureViewController presentViewController:createWrapViewController animated:NO completion:nil];
    }];
}

- (void)pickerViewController:(WLPickerViewController *)pickerViewController didSelectWrap:(WLWrap *)wrap {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    stillPictureViewController.wrap = wrap;
}

- (void)pickerViewControllerDidCancel:(WLPickerViewController *)pickerViewController {
    [pickerViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - SegmentedControlDelegate

- (BOOL)segmentedControl:(SegmentedControl*)control shouldSelectSegment:(NSInteger)segment {
    self.cameraButton.hidden = segment != 0;
    return YES;
}


@end
