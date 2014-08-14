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

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLQuickChatViewDelegate, WLPaginatedSetDelegate>

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
    
    self.liveViewSection.entries.request = [WLCandiesRequest request:self.wrap];
    self.liveViewSection.entries.request.sameDay = YES;
    
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
    
    self.quickChatView.wrap = self.wrap;
    [self refreshWrap:WLWrapContentTypeAuto];
    self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshAction) colorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.wrapViewSection setConfigure:^(WLWrapCell *cell, id entry) {
        cell.tabControl.selectedSegment = weakSelf.viewTab;
        cell.liveNotifyBulb.hidden = !weakSelf.showLiveNotifyBulb;
    }];
    
    [self.wrapViewSection setSelection:^ (id entry) {
        
    }];
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
    self.collectionView.contentOffset = CGPointZero;
}

#pragma mark - WLCandiesCellDelegate

- (void)presentCandy:(WLCandy*)candy {
    if ([candy isImage]) {
        NSMutableArray* controllers = [[self.navigationController viewControllers] mutableCopy];
		WLCandyViewController *candyController = [WLCandyViewController instantiate];
        candyController.candy = candy;
        candyController.orderBy = self.isLive ? WLCandiesOrderByUpdating : WLCandiesOrderByCreation;
        [controllers addObject:candyController];
        [self.navigationController setViewControllers:controllers animated:YES];
	} else if ([candy isMessage]) {
		[self openChat];
	}
}

- (void)candiesCell:(WLCandiesCell*)cell didSelectCandy:(WLCandy*)candy {
	[self presentCandy:candy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.isLive ? [self.liveViewSection.entries.entries count] : [self.historyViewSection.entries.entries count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString* wrapCellIdentifier = @"WLWrapCell";
        WLWrapCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:wrapCellIdentifier forIndexPath:indexPath];
        cell.entry = self.wrap;
        cell.tabControl.selectedSegment = self.viewTab;
        cell.liveNotifyBulb.hidden = !self.showLiveNotifyBulb;
        return cell;
    } else if (self.isLive) {
        WLCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCandyCellIdentifier forIndexPath:indexPath];
        WLCandy* candy = [self.liveViewSection.entries.entries tryObjectAtIndex:indexPath.item];
        cell.entry = candy;
        return cell;
    } else {
        WLCandiesCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WLCandiesCell" forIndexPath:indexPath];
        WLGroup* date = [self.historyViewSection.entries.entries tryObjectAtIndex:indexPath.item];
        cell.entry = date;
//        if (indexPath.row > 0) {
//            cell.refreshable = NO;
//        } else {
//            cell.refreshable = [date.name isEqualToString:[[NSDate serverTime] stringWithFormat:self.historyViewSection.entries.dateFormat]];
//        }
        return cell;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    [self appendDates];
    static NSString* identifier = @"WLLoadingView";
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return CGSizeMake(collectionView.width, 112);
    } else if (self.isLive) {
        CGFloat size = collectionView.width/3.0f - 0.5f;
        return CGSizeMake(size, size);
    } else {
        return CGSizeMake(collectionView.width, (collectionView.width/2.5 + 28));
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return (section != 0 && self.isLive) ? WLCandyCellSpacing : 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return (section != 0 && self.isLive) ? UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing) : UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return (section == 0) ? CGSizeZero : CGSizeMake(collectionView.width, 60);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.quickChatView onEndDragging];
    if (!decelerate) {
        [self.quickChatView onEndScrolling];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.quickChatView onEndScrolling];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.quickChatView onScroll];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	WLWrap* wrap = controller.wrap ? : self.wrap;
	[wrap uploadImage:image success:^(WLCandy *candy) {
    } failure:^(NSError *error) {
    }];
	[self setFirstContributorViewHidden:YES animated:NO];
	[self dismissViewControllerAnimated:YES completion:nil];
}

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

#pragma mark - WLCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
    [self presentCandy:candy];
}

#pragma mark - WLQuickChatViewDelegate

- (void)openChat {
    WLChatViewController * chatController = [WLChatViewController instantiate];
    chatController.wrap = self.wrap;
    [self.navigationController pushViewController:chatController animated:YES];
}

- (void)quickChatView:(WLQuickChatView *)view didOpenChat:(WLWrap *)wrap {
    [self openChat];
}

@end
