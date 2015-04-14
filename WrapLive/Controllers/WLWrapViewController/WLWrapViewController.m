
//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLCandiesCell.h"
#import "WLNavigationHelper.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLEditWrapViewController.h"
#import "UILabel+Additions.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLWrapCell.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLCandiesHistoryViewSection.h"
#import "WLCollectionViewDataProvider.h"
#import "UIScrollView+Additions.h"
#import "WLContributorsViewController.h"
#import "WLBadgeLabel.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLCreateWrapViewController.h"
#import "WLPickerViewController.h"
#import "UIFont+CustomFonts.h"
#import "WLHintView.h"
#import "WLChronologicalEntryPresenter.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLHistory *history;

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;
@property (weak, nonatomic) IBOutlet UIButton *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end

@implementation WLWrapViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[WLWrap notifier] addReceiver:self];
        [[WLCandy notifier] addReceiver:self];
        [[WLMessage notifier] addReceiver:self];
        [[WLNetwork network] addReceiver:self];
    }
    return self;
}

- (void)viewDidLoad {
    
    self.historyViewSection.defaultHeaderSize = CGSizeZero;
    
    [super viewDidLoad];
    
    self.nameLabel.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    if (!self.wrap.valid) {
        return;
    }
    
    // force set hostory mode to remove timeline from UI but keep it in code
    
    self.history = [WLHistory historyWithWrap:self.wrap];
    self.historyViewSection.entries = self.history;
    
    [self.dataProvider setRefreshableWithStyle:WLRefresherStyleOrange];
    
    [self.historyViewSection setSelection:^ (id entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:YES];
    }];
    
    [self firstLoadRequest];
    
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets inset = self.collectionView.contentInset;
    inset.top = self.contributorsLabel.superview.height;
    self.collectionView.contentInset = inset;
}

- (void)updateWrapData {
    [self.nameLabel setTitle:WLString(self.wrap.name) forState:UIControlStateNormal];
    self.contributorsLabel.text = [self.wrap contributorNames];
}

- (void)firstLoadRequest {
    if (self.history.entries.count > WLPageSize) {
        [self.history newer:nil failure:nil];
    } else {
        [self.history fresh:nil failure:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    if (self.wrap.valid) {
        [self.wrap.candies all:^(WLCandy *candy) {
            if (candy.unread) candy.unread = NO;
        }];
        [self.dataProvider reload];
        [self updateNotificationCouter];
        [self updateWrapData];
    } else {
        __weak typeof(self)weakSelf = self;
        run_after(0.5f, ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    }
    if ([self.wrap isFirstCreated]) {
        [WLHintView showInviteHintViewInView:[UIWindow mainWindow] withFocusToView:self.inviteButton];
    }
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

// MARK: - User Actions

- (IBAction)editWrapClick:(id)sender {
    WLEditWrapViewController* editWrapViewController = [WLEditWrapViewController new];
    editWrapViewController.wrap = self.wrap;
    [self presentViewController:editWrapViewController animated:YES completion:nil];
}

// MARK: - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
	return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self updateWrapData];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    [WLToast showWithMessage:[NSString stringWithFormat:WLLS(@"Wrap %@ is no longer available."),
                                  WLString([self.nameLabel titleForState:UIControlStateNormal])]];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)notifier:(WLEntryNotifier*)notifier messageAdded:(WLMessage*)message {
    [self updateNotificationCouter];
}

- (void)notifier:(WLEntryNotifier*)notifier messageDeleted:(WLMessage *)message {
    [self updateNotificationCouter];
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap ? : self.wrap;
    if (self.wrap != wrap) {
        self.view = nil;
        self.wrap = wrap;
    }
    [wrap uploadPictures:pictures];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didSelectWrap:(WLWrap *)wrap {
    WLPickerViewController *pickerViewController = [[WLPickerViewController alloc] initWithWrap:wrap delegate:self];
    [controller presentViewController:pickerViewController animated:YES completion:nil];
}

// MARK: - WLPickerViewDelegate

- (void)pickerViewControllerNewWrapClicked:(WLPickerViewController *)pickerViewController {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    [stillPictureViewController dismissViewControllerAnimated:YES completion:^{
        WLCreateWrapViewController *createWrapViewController = [WLCreateWrapViewController new];
        [createWrapViewController setCreateHandler:^(WLWrap *wrap) {
            stillPictureViewController.wrap = wrap;
            [stillPictureViewController dismissViewControllerAnimated:YES completion:NULL];
        }];
        [createWrapViewController setCancelHandler:^{
            [stillPictureViewController dismissViewControllerAnimated:YES completion:NULL];
        }];
        [stillPictureViewController presentViewController:createWrapViewController animated:YES completion:nil];
    }];
}

- (void)pickerViewController:(WLPickerViewController *)pickerViewController didSelectWrap:(WLWrap *)wrap {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    stillPictureViewController.wrap = wrap;
}

- (void)pickerViewControllerDidCancel:(WLPickerViewController *)pickerViewController {
    [pickerViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - Custom animation

- (void)dropDownCollectionView {
    self.collectionView.transform = CGAffineTransformMakeTranslation(0, -self.view.height);
    [UIView animateWithDuration:1 delay:0.2 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:0 animations:^{
        self.collectionView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

// MARK: - WLNetwork

- (void)networkDidChangeReachability:(WLNetwork *)network {
    [self.historyViewSection reload];
}

@end
