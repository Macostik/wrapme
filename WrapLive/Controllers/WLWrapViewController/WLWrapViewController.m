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
#import "WLEditWrapViewController.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLAPIManager.h"
#import "WLComment.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLEntryNotifier.h"
#import "UILabel+Additions.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLQuickChatView.h"
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
#import "WLSupportFunctions.h"
#import "WLSession.h"
#import "NSString+Additions.h"
#import "WLContributorsViewController.h"
#import "WLNotification.h"
#import "WLSizeToFitLabel.h"

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
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *messageCountLabel;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    
    self.historyViewSection.defaultHeaderSize = CGSizeZero;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    if (!self.wrap.valid) {
        return;
    }
    
    [self updateWrapData];
    
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
    
    self.dataProvider.animationViews = self.timelineDataProvider.animationViews;
}

- (void)updateWrapData {
    self.nameLabel.text = WLString(self.wrap.name);
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
     self.isShowPlaceholder = ![self.wrap.candies.array nonempty];
}

- (void)showPlaceholder {
    [super showPlaceholder];
    self.noContentPlaceholder.y -= 20;
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
    self.nameLabel.width = self.messageCountLabel.hidden ? self.nameLabel.width : self.messageCountLabel.x - self.nameLabel.x;
}

- (void)reloadData {
    [self.historyViewSection.entries resetEntries:self.wrap.candies];
}

- (UIViewController *)shakePresentedViewController {
	__weak typeof(self)weakSelf = self;
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.wrap = weakSelf.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

#pragma mark - WLEntryNotifyReceiver

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
	return self.wrap;
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self updateWrapData];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
	[WLToast showWithMessage:[NSString stringWithFormat:@"Wrap %@ is no longer avaliable.", WLString(self.nameLabel.text)]];
	__weak typeof(self)weakSelf = self;
	run_after(0.5f, ^{
		[weakSelf.navigationController popToRootViewControllerAnimated:YES];
	});
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self.groups addEntry:candy];
    self.isShowPlaceholder = ![self.wrap.candies.array nonempty];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self.groups removeEntry:candy];
    self.isShowPlaceholder = ![self.wrap.candies.array nonempty];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.wrap = self.wrap;
		controller.mode = WLCameraModeCandy;
		controller.delegate = self;
	} else {
        [(WLContributorsViewController*)segue.destinationViewController setWrap:self.wrap];
    }
}

- (IBAction)editWrap:(id)sender {
	WLEditWrapViewController* controller = [WLEditWrapViewController instantiate];
	controller.wrap = self.wrap;
    [self.navigationController pushViewController:controller animated:YES];
}

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
        [WLSession setInteger:self.mode key:WLWrapViewDefaultModeKey];
        self.historyViewSection.completed = NO;
        [self.collectionView scrollToTopAnimated:YES];
        [self.dataProvider reload];
    }
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
	chatController.wrap = self.wrap;
	chatController.shouldShowKeyboard = YES;
    [self.wrap.messages all:^(WLMessage *message) {
        if(!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    }];
	[self.navigationController pushUniqueClassViewController:chatController animated:YES];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap ? : self.wrap;
    [wrap uploadPictures:pictures];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
