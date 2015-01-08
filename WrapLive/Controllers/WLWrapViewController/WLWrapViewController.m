
//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLCandiesCell.h"
#import "WLImageFetcher.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "UIView+Shorthand.h"
#import "WLNavigation.h"
#import "WLCameraViewController.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLAPIManager.h"
#import "WLComment.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLEntryNotifier.h"
#import "WLEditWrapViewController.h"
#import "UILabel+Additions.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLWrapCell.h"
#import "UIView+AnimationHelper.h"
#import "NSDate+Additions.h"
#import "WLHistory.h"
#import "NSString+Additions.h"
#import "WLWrapRequest.h"
#import "SegmentedControl.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLCandiesRequest.h"
#import "UIViewController+Additions.h"
#import "WLCandiesHistoryViewSection.h"
#import "WLCollectionViewDataProvider.h"
#import "WLTimelineViewDataProvider.h"
#import "WLTimeline.h"
#import "UIScrollView+Additions.h"
#import "WLSession.h"
#import "NSString+Additions.h"
#import "WLContributorsViewController.h"
#import "WLNotification.h"
#import "WLBadgeLabel.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLCreateWrapViewController.h"
#import "WLPickerViewController.h"
#import "UIFont+CustomFonts.h"

typedef NS_ENUM(NSUInteger, WLWrapViewMode) {
    WLWrapViewModeTimeline,
    WLWrapViewModeHistory
};

static NSString* WLWrapViewDefaultModeKey = @"WLWrapViewDefaultModeKey";
static NSString* WLWrapPlaceholderViewTimeline = @"WLWrapPlaceholderViewTimeline";
static NSString* WLWrapPlaceholderViewHistory = @"WLWrapPlaceholderViewHistory";
static CGFloat const WLIndent = 12.0f;

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *viewButton;

@property (strong, nonatomic) WLHistory *history;

@property (nonatomic) WLWrapViewMode mode;

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;
@property (strong, nonatomic) IBOutlet WLTimelineViewDataProvider *timelineDataProvider;
@property (weak, nonatomic) IBOutlet UIButton *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightViewConstraint;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    
    self.historyViewSection.defaultHeaderSize = CGSizeZero;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setPlaceholderNib:[UINib nibWithNibName:WLWrapPlaceholderViewTimeline bundle:nil] forType:WLWrapViewModeTimeline];
    [self setPlaceholderNib:[UINib nibWithNibName:WLWrapPlaceholderViewHistory bundle:nil] forType:WLWrapViewModeHistory];
    
    self.nameLabel.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    if (!self.wrap.valid) {
        return;
    }
    
    // force set hostory mode to remove timeline from UI but keep it in code
    self.mode = WLWrapViewModeHistory;
    
    self.history = [WLHistory historyWithWrap:self.wrap];
    self.historyViewSection.entries = self.history;
    self.timelineDataProvider.timeline = [WLTimeline timelineWithWrap:self.wrap];
    
    [self.dataProvider setRefreshableWithStyle:WLRefresherStyleOrange];
    
    [[WLWrap notifier] addReceiver:self];
	[[WLCandy notifier] addReceiver:self];
	[[WLMessage notifier] addReceiver:self];
    
    [self.historyViewSection setSelection:^ (id entry) {
        [entry present];
    }];
    self.timelineDataProvider.selection = self.historyViewSection.selection;
    
    [self firstLoadRequest];
    
    self.dataProvider.animatableConstraints = self.timelineDataProvider.animatableConstraints;
    if (![self placeholderVisibleForType:self.mode]) {
        [self dropDownCollectionView];
    }
}

- (void)updateWrapData {
    [self.nameLabel setTitle:WLString(self.wrap.name) forState:UIControlStateNormal];
    self.contributorsLabel.text = [self.wrap contributorNames];
    CGFloat height = [self.contributorsLabel.text heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight
                                                                                        preset:WLFontPresetSmall]
                                                           width:self.view.width - WLIndent * 2];
    if (height > self.contributorsLabel.height) {
        CGFloat defaultHeight = self.contributorsLabel.height;
        self.heightViewConstraint.constant = height + WLIndent * 2;
        [self.contributorsLabel.superview layoutIfNeeded];
        UIEdgeInsets inset = self.collectionView.contentInset;
        inset.top = self.collectionView.contentInset.top + (height - defaultHeight);
        self.collectionView.contentInset = inset;
    }
}

- (void)firstLoadRequest {
    __weak typeof(self)weakSelf = self;
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypePaginated;
    wrapRequest.type = [self.history.entries count] > 10 ? WLPaginatedRequestTypeNewer : WLPaginatedRequestTypeFresh;
    wrapRequest.newer = [[self.history.entries firstObject] date];
    [wrapRequest send:^(NSOrderedSet *orderedSet) {
        [weakSelf reloadData];
        if (weakSelf.mode == WLWrapViewModeTimeline && !weakSelf.timelineDataProvider.timeline.entries.nonempty) {
            [weakSelf changeMode:WLWrapViewModeHistory];
            [weakSelf dropDownCollectionView];
        }
    } failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    if (!self.wrap.valid) {
        __weak typeof(self)weakSelf = self;
        run_after(0.5f, ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
        return;
    }
    
    [self.dataProvider reload];
    [self updateNotificationCouter];
    [self updateWrapData];
    [self updatePlaceholderVisibilityForType:self.mode];
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
}

- (void)reloadData {
    [self.history resetEntries:self.wrap.candies];
}

- (UIViewController *)shakePresentedViewController {
    WLStillPictureViewController *controller = [WLStillPictureViewController instantiate:
                                                [UIStoryboard storyboardNamed:WLCameraStoryboard]];
    controller.wrap = self.wrap;
    controller.delegate = self;
    controller.mode = WLStillPictureModeDefault;
    
	return controller;
}

- (IBAction)editWrapClick:(id)sender {
    WLEditWrapViewController* editWrapViewController = [WLEditWrapViewController new];
    editWrapViewController.wrap = self.wrap;
    [self presentViewController:editWrapViewController animated:YES completion:nil];
}

- (BOOL)placeholderVisibleForType:(NSUInteger)type {
    if (type == WLWrapViewModeTimeline) {
        return !self.timelineDataProvider.timeline.entries.nonempty;
    } else {
        return !self.wrap.candies.nonempty;
    }
}

#pragma mark - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
	return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self updateWrapData];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
	[WLToast showWithMessage:[NSString stringWithFormat:WLLS(@"Wrap %@ is no longer available."),
                              WLString([self.nameLabel titleForState:UIControlStateNormal])]];
	__weak typeof(self)weakSelf = self;
	run_after(0.5f, ^{
		[weakSelf.navigationController popToRootViewControllerAnimated:YES];
	});
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self updatePlaceholderVisibilityForType:self.mode];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self updatePlaceholderVisibilityForType:self.mode];
}

- (void)notifier:(WLEntryNotifier*)notifier messageAdded:(WLMessage*)message {
    [self updateNotificationCouter];
}

- (void)notifier:(WLEntryNotifier*)notifier messageDeleted:(WLMessage *)message {
    [self updateNotificationCouter];
}

#pragma mark - User Actions

- (void)setMode:(WLWrapViewMode)mode {
    _mode = mode;
    if (mode == WLWrapViewModeTimeline) {
        [self.timelineDataProvider connect];
    } else {
        [self.dataProvider connect];
    }
    self.viewButton.selected = mode == WLWrapViewModeHistory;
    
    [self updatePlaceholderVisibilityForType:self.mode];
}

- (IBAction)viewChanged:(UIButton*)sender {
      [self dropUpCollectionView];
    [self changeMode:sender.selected ? WLWrapViewModeTimeline : WLWrapViewModeHistory];
  
}

- (void)changeMode:(WLWrapViewMode)mode {
    if (_mode != mode) {
        self.mode = mode;
        if (mode == WLWrapViewModeTimeline) {
            [self.timelineDataProvider.timeline update];
        } else {
            [self.history addEntries:self.wrap.candies];
        }
        [WLSession setInteger:self.mode key:WLWrapViewDefaultModeKey];
        self.historyViewSection.completed = NO;
        [self.collectionView setMinimumContentOffsetAnimated:YES];
        [self.dataProvider reload];
    }
}

#pragma mark - WLStillPictureViewControllerDelegate

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

#pragma mark - WLPickerViewDelegate

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
    [pickerViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Custom animation

- (void)dropUpCollectionView {
    if (self.wrap.candies.nonempty) {
        [self.collectionView revealFrom:kCATransitionFromTop withDuration:1 delegate:nil];
    }
}

- (void)dropDownCollectionView {
    if (self.wrap.candies.nonempty) {
        self.collectionView.transform = CGAffineTransformMakeTranslation(0, -self.view.height);
        [UIView animateWithDuration:1 delay:0.2 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:0 animations:^{
            self.collectionView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
        }];
    }
}

@end
