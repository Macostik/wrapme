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
#import "WLCreateWrapViewController.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLAPIManager.h"
#import "WLComment.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLWrapBroadcaster.h"
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
#import "WLServerTime.h"
#import "SegmentedControl.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLCandiesRequest.h"
#import "UIViewController+Additions.h"
#import "WLCandiesHistoryViewSection.h"
#import "WLCandiesLiveViewSection.h"
#import "WLCollectionViewDataProvider.h"

typedef NS_ENUM(NSUInteger, WLWrapViewTab) {
    WLWrapViewTabLive,
    WLWrapViewTabHistory
};

static NSString* WLWrapViewDefaultTabKey = @"WLWrapViewDefaultTabKey";

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, WLPaginatedSetDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet WLQuickChatView *quickChatView;

@property (strong, nonatomic) WLWrapRequest* wrapRequest;

@property (strong, nonatomic) WLCandiesRequest* candiesRequest;

@property (strong, nonatomic) WLGroupedSet *groups;

@property (nonatomic) WLWrapViewTab viewTab;

@property (nonatomic, readonly) BOOL isLive;

@property (nonatomic) BOOL showLiveNotifyBulb;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *wrapViewSection;
@property (strong, nonatomic) IBOutlet WLCandiesLiveViewSection *liveViewSection;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.wrap.valid) {
        return;
    }
    
    [self.wrapViewSection setFooterSize:^CGSize(NSUInteger section) {
        return CGSizeZero;
    }];
    
    self.wrapViewSection.entries = [NSMutableOrderedSet orderedSetWithObject:self.wrap];
    
    NSNumber* defaultTab = [[NSUserDefaults standardUserDefaults] objectForKey:WLWrapViewDefaultTabKey];
    if (defaultTab) {
        self.viewTab = [defaultTab integerValue];
    } else {
        self.viewTab = WLWrapViewTabHistory;
    }
    
    self.groups = [WLGroupedSet groupsOrderedBy:WLCandiesOrderByCreation];
    self.groups.delegate = self;
    [self.groups addEntries:self.wrap.candies];
    self.historyViewSection.entries = self.groups;
    self.historyViewSection.entries.request = self.wrapRequest;
    self.liveViewSection.entries = [self.groups group:[NSDate date]];
    self.liveViewSection.entries.request = [WLCandiesRequest request:self.wrap];
    self.liveViewSection.entries.request.sameDay = YES;
    
    self.quickChatView.wrap = self.wrap;
    [self refreshWrap:WLWrapContentTypeAuto];
    self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshAction) colorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.wrapViewSection setConfigure:^(WLWrapCell *cell, id entry) {
        cell.tabControl.selectedSegment = weakSelf.viewTab;
        cell.liveNotifyBulb.hidden = !weakSelf.showLiveNotifyBulb;
    }];
    
    [self.historyViewSection setSelection:^ (id entry) {
        [weakSelf presentCandy:entry];
    }];
    self.liveViewSection.selection = self.historyViewSection.selection;
}

- (BOOL)isLive {
    return self.viewTab == WLWrapViewTabLive;
}

- (WLWrapRequest *)wrapRequest {
    if (!_wrapRequest) {
        _wrapRequest = [WLWrapRequest request];
    }
    _wrapRequest.wrap = self.wrap;
    return _wrapRequest;
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
    
    self.wrap.unread = @NO;
    [self.collectionView reloadData];
}

- (void)refreshAction {
    [self refreshWrap:self.isLive ? WLWrapContentTypeLive : WLWrapContentTypeHistory];
}

- (void)refreshWrap:(NSString*)contentType {
	__weak typeof(self)weakSelf = self;
    self.wrapRequest.page = 1;
    self.wrapRequest.contentType = contentType;
    [self.wrapRequest send:^(NSOrderedSet* candies) {
        if (contentType == WLWrapContentTypeAuto && [weakSelf.wrapRequest.contentType isEqualToString:WLWrapContentTypeLive] && weakSelf.viewTab == WLWrapViewTabHistory) {
            if ([[[[weakSelf.wrap liveCandies] firstObject] contributor] isEqualToEntry:[WLUser currentUser]]) {
                weakSelf.showLiveNotifyBulb = NO;
            } else  {
                weakSelf.showLiveNotifyBulb = YES;
            }
        }
        [weakSelf reloadData];
        [weakSelf setFirstContributorViewHidden:weakSelf.wrap.candies.nonempty animated:YES];
		[weakSelf.refresher endRefreshing];
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
		[weakSelf.refresher endRefreshing];
    }];
}

- (void)reloadData {
    [self.historyViewSection.entries resetEntries:self.wrap.candies];
    [self.liveViewSection.entries resetEntries:[self.wrap liveCandies]];
}

- (void)appendDates {
    __weak typeof(self)weakSelf = self;
    if (self.isLive) {
        if (!self.liveViewSection.entries.entries.nonempty) {
            [self refreshWrap:WLWrapContentTypeLive];
            return;
        }
        self.candiesRequest = [WLCandiesRequest request:self.wrap];
        self.candiesRequest.newer = [[self.liveViewSection.entries.entries firstObject] updatedAt];
        self.candiesRequest.older = [[self.liveViewSection.entries.entries lastObject] updatedAt];
        self.candiesRequest.type = WLPaginatedRequestTypeOlder;
        self.candiesRequest.sameDay = YES;
        [self.candiesRequest send:^(NSOrderedSet* candies) {
            [weakSelf.liveViewSection.entries.entries unionOrderedSet:candies];
            [weakSelf.historyViewSection.entries addEntries:candies];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
        }];
    } else {
        if (!self.wrap.candies.nonempty) {
            [self refreshWrap:WLWrapContentTypeHistory];
            return;
        }
        self.wrapRequest.page = ((self.historyViewSection.entries.entries.count + 1)/WLAPIDatePageSize + 1);
        [self.wrapRequest send:^(NSOrderedSet* candies) {
            [weakSelf.historyViewSection.entries addEntries:weakSelf.wrap.candies];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
        }];
    }
}

- (UIViewController *)shakePresentedViewController {
	return [self cameraViewController];
}

- (id)cameraViewController {
	__weak typeof(self)weakSelf = self;
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.wrap = weakSelf.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
	chatController.wrap = self.wrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

- (void)setFirstContributorViewHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.firstContributorView.alpha = hidden ? 0.0f : 1.0f;
    }];
    if (!hidden) {
        self.firstContributorWrapNameLabel.text = self.wrap.name;
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	self.quickChatView.wrap = self.wrap;
    __weak typeof(self)weakSelf = self;
    run_after(0.0, ^{
        if (weakSelf.isLive) {
            [weakSelf.liveViewSection.entries resetEntries:[weakSelf.wrap liveCandies]];
            [weakSelf.collectionView reloadData];
        }
    });
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    [self.historyViewSection.entries addEntry:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [self.historyViewSection.entries removeEntry:candy];
    if (!self.wrap.candies.nonempty) {
        [self setFirstContributorViewHidden:NO animated:self.isOnTopOfNagvigation];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self.historyViewSection.entries sort:candy];
    if (self.isLive) {
        [self.liveViewSection.entries.entries sortByUpdatedAtDescending];
        [self.collectionView reloadData];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
    WLWrapCell* cell = (id)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([cell isKindOfClass:[WLWrapCell class]]) {
        [WLToast showWithMessage:[NSString stringWithFormat:@"Wrap %@ is no longer avaliable.", WLString(cell.nameLabel.text)]];
    }
    __weak typeof(self)weakSelf = self;
    run_after(0.5f, ^{
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
    });
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.wrap;
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self.collectionView reloadData];
}

#pragma mark - User Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.wrap = self.wrap;
		controller.mode = WLCameraModeCandy;
		controller.delegate = self;
        [self setFirstContributorViewHidden:YES animated:YES];
	}
}

- (IBAction)notNow:(UIButton *)sender {
	[self setFirstContributorViewHidden:YES animated:YES];
}

- (IBAction)editWrap:(id)sender {
	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
	controller.wrap = self.wrap;
	[controller presentInViewController:self transition:WLWrapTransitionFromRight];
}

- (void)setViewTab:(WLWrapViewTab)viewTab {
    _viewTab = viewTab;
    if (self.isLive) {
        self.dataProvider.sections = [NSMutableArray arrayWithObjects:self.wrapViewSection, self.liveViewSection, nil];
    } else {
        self.dataProvider.sections = [NSMutableArray arrayWithObjects:self.wrapViewSection, self.historyViewSection, nil];
    }
}

- (IBAction)tabChanged:(SegmentedControl *)sender {
    self.viewTab = sender.selectedSegment;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.viewTab) forKey:WLWrapViewDefaultTabKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self didChangeViewTab];
}

- (void)didChangeViewTab {
    if (self.isLive) {
        self.showLiveNotifyBulb = NO;
        [self.liveViewSection.entries resetEntries:[self.wrap liveCandies]];
    }
    self.liveViewSection.completed = NO;
    self.historyViewSection.completed = NO;
    [self.collectionView setContentOffset:CGPointZero animated:YES];
}

- (void)presentCandy:(WLCandy*)candy {
    if ([candy isImage]) {
		WLCandyViewController *candyController = (id)[candy viewController];
        candyController.orderBy = self.isLive ? WLCandiesOrderByUpdating : WLCandiesOrderByCreation;
        [self.navigationController pushViewController:candyController animated:YES];
	} else if ([candy isMessage]) {
        [candy presentInViewController:self];
	}
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    if (self.viewTab != WLWrapViewTabLive) {
        self.viewTab = WLWrapViewTabLive;
        [self didChangeViewTab];
    }
    WLWrap* wrap = controller.wrap ? : self.wrap;
    [wrap uploadPictures:pictures];
    [self setFirstContributorViewHidden:YES animated:NO];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self setFirstContributorViewHidden:YES animated:NO];
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
