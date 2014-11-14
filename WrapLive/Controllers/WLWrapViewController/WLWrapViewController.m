
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
#import "WLGroupedSet.h"
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
#import "WLSizeToFitLabel.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLActionViewController.h"

typedef NS_ENUM(NSUInteger, WLWrapViewMode) {
    WLWrapViewModeTimeline,
    WLWrapViewModeHistory
};

static NSString* WLWrapViewDefaultModeKey = @"WLWrapViewDefaultModeKey";

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *viewButton;

@property (strong, nonatomic) WLGroupedSet *groups;

@property (nonatomic) WLWrapViewMode mode;

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;
@property (strong, nonatomic) IBOutlet WLTimelineViewDataProvider *timelineDataProvider;
@property (weak, nonatomic) IBOutlet UIButton *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewConstraint;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    
    self.historyViewSection.defaultHeaderSize = CGSizeZero;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.nameLabel.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    if (!self.wrap.valid) {
        return;
    }
    
    self.mode = [WLSession integer:WLWrapViewDefaultModeKey];
    
    self.groups = [[WLGroupedSet alloc] init];
    [self.groups addEntries:self.wrap.candies];
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypePaginated;
    self.historyViewSection.entries = self.groups;
    self.historyViewSection.entries.request = wrapRequest;
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
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
}

- (void)updateWrapData {
    [self.nameLabel setTitle:WLString(self.wrap.name) forState:UIControlStateNormal];
    self.contributorsLabel.text = [self.wrap contributorNames];
}

- (void)firstLoadRequest {
    __weak typeof(self)weakSelf = self;
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypePaginated;
    wrapRequest.type = [self.groups.entries count] > 10 ? WLPaginatedRequestTypeNewer : WLPaginatedRequestTypeFresh;
    wrapRequest.newer = [[self.groups.entries firstObject] date];
    [wrapRequest send:^(NSOrderedSet *orderedSet) {
        [weakSelf reloadData];
        if (weakSelf.mode == WLWrapViewModeTimeline && !weakSelf.timelineDataProvider.timeline.entries.nonempty) {
            [weakSelf changeMode:WLWrapViewModeHistory];
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
    self.showsPlaceholderView = !self.wrap.candies.nonempty;
}

- (UINib *)placeholderViewNib {
    return [UINib nibWithNibName:@"WLWrapPlaceholderView" bundle:nil];
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
}

- (void)reloadData {
    [self.groups resetEntries:self.wrap.candies];
}

- (UIViewController *)shakePresentedViewController {
    WLStillPictureViewController *controller = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    controller.wrap = self.wrap;
    controller.delegate = self;
    controller.mode = WLCameraModeCandy;
	return controller;
}

- (IBAction)editWrapClick:(id)sender {
    [WLActionViewController addViewControllerByClass:[WLEditWrapViewController class]
                                           withEntry:self.wrap
                              toParentViewController:self];
}

#pragma mark - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
	return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self updateWrapData];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
	[WLToast showWithMessage:[NSString stringWithFormat:@"Wrap %@ is no longer avaliable.", WLString([self.nameLabel titleForState:UIControlStateNormal])]];
	__weak typeof(self)weakSelf = self;
	run_after(0.5f, ^{
		[weakSelf.navigationController popToRootViewControllerAnimated:YES];
	});
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self.groups addEntry:candy];
    self.showsPlaceholderView = !self.wrap.candies.nonempty;
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self.groups removeEntry:candy];
    self.showsPlaceholderView = !self.wrap.candies.nonempty;
}

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
    [self.groups sort:candy];
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
}

- (IBAction)viewChanged:(UIButton*)sender {
    [self changeMode:sender.selected ? WLWrapViewModeTimeline : WLWrapViewModeHistory];
}

- (void)changeMode:(WLWrapViewMode)mode {
    if (_mode != mode) {
        self.mode = mode;
        if (mode == WLWrapViewModeTimeline) {
            [self.timelineDataProvider.timeline update];
        } else {
            [self.groups addEntries:self.wrap.candies];
        }
        [self dropUpCollectionView];
        [WLSession setInteger:self.mode key:WLWrapViewDefaultModeKey];
        self.historyViewSection.completed = NO;
        [self.collectionView scrollToTopAnimated:YES];
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

#pragma mark - Custom animation

- (void)dropUpCollectionView {
    [self.collectionView revealFrom:kCATransitionFromTop withDuration:1 delegate:nil];
}

- (void)dropDownCollectionView {
    self.collectionView.transform = CGAffineTransformMakeTranslation(0, -self.view.height);
    [UIView animateWithDuration:1 delay:0.2 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:0 animations:^{
        self.collectionView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

@end
