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

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;

@property (strong, nonatomic) WLGroupedSet *groups;

@property (nonatomic) WLWrapViewTab viewTab;

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *wrapViewSection;
@property (strong, nonatomic) IBOutlet WLCandiesLiveViewSection *liveViewSection;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;

@end

@implementation WLWrapViewController

@synthesize viewTab = _viewTab;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.wrap.valid) {
        return;
    }
    
    self.wrapViewSection.defaultFooterSize = CGSizeZero;
    
    self.wrapViewSection.entries = [NSMutableOrderedSet orderedSetWithObject:self.wrap];
    
    NSNumber* defaultTab = [[NSUserDefaults standardUserDefaults] objectForKey:WLWrapViewDefaultTabKey];
    self.viewTab = defaultTab ? [defaultTab integerValue] : WLWrapViewTabHistory;
    
    self.groups = [WLGroupedSet groupsOrderedBy:WLCandiesOrderByCreation];
    [self.groups addEntries:self.wrap.candies];
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypeHistory;
    self.historyViewSection.entries = self.groups;
    self.historyViewSection.entries.request = wrapRequest;
    self.liveViewSection.entries = [self.groups group:[NSDate date]];
    self.liveViewSection.entries.request = [WLCandiesRequest request:self.wrap];
    self.liveViewSection.entries.request.sameDay = YES;
    wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypeLive;
    self.liveViewSection.wrapRequest = wrapRequest;
    
    [self.dataProvider setRefreshableWithColorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.wrapViewSection setConfigure:^(WLWrapCell *cell, id entry) {
        cell.tabControl.selectedSegment = weakSelf.viewTab;
    }];
    
    [self.historyViewSection setSelection:^ (id entry) {
        [weakSelf presentCandy:entry];
    }];
    self.liveViewSection.selection = self.historyViewSection.selection;
    
    [self firstLoadRequest];
}

- (void)firstLoadRequest {
    __weak typeof(self)weakSelf = self;
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypeAuto;
    [wrapRequest send:^(NSOrderedSet *orderedSet) {
        if ([wrapRequest isContentType:WLWrapContentTypeLive]) {
            [weakSelf changeViewTab:WLWrapViewTabLive];
        } else if ([wrapRequest isContentType:WLWrapContentTypeHistory]) {
            [weakSelf changeViewTab:WLWrapViewTabHistory];
        } else {
            [weakSelf reloadData];
        }
        [weakSelf setFirstContributorViewHidden:weakSelf.wrap.candies.nonempty animated:YES];
    } failure:^(NSError *error) {
        [error show];
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
    
    self.wrap.unread = @NO;
    [self.dataProvider reload];
}

- (void)reloadData {
    [self.historyViewSection.entries resetEntries:self.wrap.candies];
    self.liveViewSection.entries = [self.groups group:[NSDate date]];
}

- (UIViewController *)shakePresentedViewController {
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

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    [self.groups addEntry:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [self.groups removeEntry:candy];
    if (!self.wrap.candies.nonempty) {
        [self setFirstContributorViewHidden:NO animated:self.isOnTopOfNagvigation];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self.groups sort:candy];
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
    if (viewTab == WLWrapViewTabLive) {
        self.dataProvider.sections = [NSMutableArray arrayWithObjects:self.wrapViewSection, self.liveViewSection, nil];
    } else {
        self.dataProvider.sections = [NSMutableArray arrayWithObjects:self.wrapViewSection, self.historyViewSection, nil];
    }
}

- (IBAction)tabChanged:(SegmentedControl *)sender {
    [self changeViewTab:sender.selectedSegment];
}

- (void)changeViewTab:(WLWrapViewTab)viewTab {
    if (_viewTab != viewTab) {
        self.viewTab = viewTab;
        [[NSUserDefaults standardUserDefaults] setObject:@(self.viewTab) forKey:WLWrapViewDefaultTabKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self didChangeViewTab];
    }
}

- (void)didChangeViewTab {
    self.liveViewSection.completed = NO;
    self.historyViewSection.completed = NO;
    [self.collectionView setContentOffset:CGPointZero animated:YES];
    [self.dataProvider reload];
}

- (void)presentCandy:(WLCandy*)candy {
    if ([candy isImage]) {
		WLCandyViewController *candyController = (id)[candy viewController];
        candyController.orderBy = (self.viewTab == WLWrapViewTabLive) ? WLCandiesOrderByUpdating : WLCandiesOrderByCreation;
        [self.navigationController pushViewController:candyController animated:YES];
	} else if ([candy isMessage]) {
        [candy presentInViewController:self];
	}
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    [self changeViewTab:WLWrapViewTabLive];
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
