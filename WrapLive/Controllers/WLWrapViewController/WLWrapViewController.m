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
#import "WLCollectionViewDataProvider.h"
#import "WLTimelineViewDataProvider.h"
#import "WLTimeline.h"
#import "UIScrollView+Additions.h"
#import "WLSupportFunctions.h"
#import "WLSession.h"
#import "NSString+Additions.h"

typedef NS_ENUM(NSUInteger, WLWrapViewTab) {
    WLWrapViewTabLive,
    WLWrapViewTabHistory
};

static NSString* WLWrapViewDefaultTabKey = @"WLWrapViewDefaultTabKey";

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *viewButton;

@property (strong, nonatomic) WLGroupedSet *groups;

@property (nonatomic) WLWrapViewTab viewTab;

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCandiesHistoryViewSection *historyViewSection;
@property (strong, nonatomic) IBOutlet WLTimelineViewDataProvider *timelineDataProvider;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLImageView *coverView;

@end

@implementation WLWrapViewController

@synthesize viewTab = _viewTab;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.wrap.valid) {
        return;
    }
    
    [self updateWrapData];
    
    self.historyViewSection.defaultFooterSize = CGSizeZero;
    self.historyViewSection.defaultHeaderSize = CGSizeZero;
    
    self.viewTab = [WLSession integer:WLWrapViewDefaultTabKey];
    
    self.groups = [[WLGroupedSet alloc] init];
    [self.groups addEntries:self.wrap.candies];
    WLWrapRequest* wrapRequest = [WLWrapRequest request:self.wrap];
    wrapRequest.contentType = WLWrapContentTypeHistory;
    self.historyViewSection.entries = self.groups;
    self.historyViewSection.entries.request = wrapRequest;
    self.timelineDataProvider.timeline = [WLTimeline timelineWithWrap:self.wrap];
    
    [self.dataProvider setRefreshableWithColorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.historyViewSection setSelection:^ (id entry) {
        if ([entry isKindOfClass:[WLComment class]]) {
            entry = [entry candy];
        }
        [entry presentInViewController:weakSelf];
    }];
    self.timelineDataProvider.selection = self.historyViewSection.selection;
    
    [self firstLoadRequest];
    
    self.dataProvider.animationViews = self.timelineDataProvider.animationViews;
}

- (void)updateWrapData {
    self.nameLabel.text = WLString(self.wrap.name);
    NSString* url = [self.wrap.picture anyUrl];
    self.coverView.url = url;
    self.contributorsLabel.text = [self.wrap contributorNames];
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
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
    
    if (!NSNumberEqual(self.wrap.unread, @NO)) self.wrap.unread = @NO;
    [self.dataProvider reload];
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

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
    [self updateWrapData];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    [self.groups addEntry:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [self.groups removeEntry:candy];
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

- (NSInteger)broadcasterPreferedCandyType:(WLWrapBroadcaster *)broadcaster {
    return WLCandyTypeImage;
}

#pragma mark - User Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.wrap = self.wrap;
		controller.mode = WLCameraModeCandy;
		controller.delegate = self;
	}
}

- (IBAction)editWrap:(id)sender {
//	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
//	controller.wrap = self.wrap;
//	[controller presentInViewController:self transition:WLWrapTransitionFromRight];
}

- (void)setViewTab:(WLWrapViewTab)viewTab {
    _viewTab = viewTab;
    if (viewTab == WLWrapViewTabLive) {
        [self.timelineDataProvider connect];
    } else {
        [self.dataProvider connect];
    }
    self.viewButton.selected = viewTab == WLWrapViewTabHistory;
}

- (IBAction)viewChanged:(UIButton*)sender {
    [self changeViewTab:!sender.selected ? WLWrapViewTabHistory : WLWrapViewTabLive];
}

- (void)changeViewTab:(WLWrapViewTab)viewTab {
    if (_viewTab != viewTab) {
        self.viewTab = viewTab;
        [WLSession setInteger:self.viewTab key:WLWrapViewDefaultTabKey];
        self.historyViewSection.completed = NO;
        [self.collectionView scrollToTopAnimated:YES];
        [self.dataProvider reload];
    }
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
	chatController.wrap = self.wrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    [self changeViewTab:WLWrapViewTabLive];
    WLWrap* wrap = controller.wrap ? : self.wrap;
    [wrap uploadPictures:pictures];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
