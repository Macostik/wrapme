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
#import "WLDatesViewController.h"
#import "WLServerTime.h"
#import "SegmentedControl.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLCandiesRequest.h"
#import "UIViewController+Additions.h"

typedef NS_ENUM(NSUInteger, WLWrapViewTab) {
    WLWrapViewTabLive,
    WLWrapViewTabHistory
};

static NSString* WLWrapViewDefaultTabKey = @"WLWrapViewDefaultTabKey";

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLCandiesCellDelegate, WLWrapBroadcastReceiver, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLWrapCellDelegate, WLQuickChatViewDelegate, WLGroupedSetDelegate, WLCandyCellDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet WLQuickChatView *quickChatView;

@property (strong, nonatomic) WLGroupedSet* groups;

@property (strong, nonatomic) NSMutableOrderedSet* candies;

@property (nonatomic) BOOL showLoadingView;

@property (strong, nonatomic) WLWrapRequest* wrapRequest;

@property (strong, nonatomic) WLCandiesRequest* candiesRequest;

@property (nonatomic) WLWrapViewTab viewTab;

@property (nonatomic, readonly) BOOL isLive;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.wrap.valid) {
        return;
    }
    
    NSNumber* defaultTab = [[NSUserDefaults standardUserDefaults] objectForKey:WLWrapViewDefaultTabKey];
    if (defaultTab) {
        self.viewTab = [defaultTab integerValue];
    } else {
        self.viewTab = WLWrapViewTabHistory;
    }
    
    self.groups = [WLGroupedSet groupsOrderedBy:WLCandiesOrderByCreation];
    self.groups.skipToday = YES;
    self.groups.delegate = self;
    
    self.showLoadingView = YES;
    self.quickChatView.wrap = self.wrap;
    [self refreshWrap:WLWrapContentTypeAuto];
    self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshAction) colorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    [self.groups addCandies:self.wrap.candies];
    self.candies = [self.wrap liveCandies];
    
    [self.collectionView registerNib:[WLCandyCell nib] forCellWithReuseIdentifier:WLCandyCellIdentifier];
}

- (BOOL)isLive {
    return self.viewTab == WLWrapViewTabLive;
}

- (void)setShowLoadingView:(BOOL)showLoadingView {
    _showLoadingView = showLoadingView;
    [self.collectionView reloadData];
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
    NSArray* cells = [[self.collectionView visibleCells] selectObjects:^BOOL(id item) {
        return [item isKindOfClass:[WLCandiesCell class]];
    }];
    if (cells.nonempty) {
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        for (WLCandiesCell* cell in cells) {
            [cell.collectionView reloadData];
        }
    } else {
        [self.collectionView reloadData];
    }
}

- (void)refreshAction {
    [self refreshWrap:self.isLive ? WLWrapContentTypeLive : WLWrapContentTypeHistory];
}

- (void)refreshWrap:(NSString*)contentType {
	__weak typeof(self)weakSelf = self;
    if (self.wrapRequest.loading) return;
    self.wrapRequest.page = 1;
    self.wrapRequest.contentType = contentType;
    [self.wrapRequest send:^(WLWrap* wrap) {
        if (contentType == WLWrapContentTypeAuto) {
            if ([weakSelf.wrapRequest isContentType:WLWrapContentTypeLive] && weakSelf.viewTab == WLWrapViewTabHistory) {
                [weakSelf changeViewTab:WLWrapViewTabLive];
            } else if ([weakSelf.wrapRequest isContentType:WLWrapContentTypeHistory] && weakSelf.viewTab == WLWrapViewTabLive) {
                [weakSelf changeViewTab:WLWrapViewTabHistory];
            } else {
                [weakSelf reloadData];
            }
        } else {
            [weakSelf reloadData];
        }
        [weakSelf setFirstContributorViewHidden:wrap.candies.nonempty animated:YES];
		[weakSelf.refresher endRefreshing];
        if (!wrap.candies.nonempty) {
            weakSelf.showLoadingView = NO;
        }
    } failure:^(NSError *error) {
        if ([weakSelf.wrapRequest.contentType isEqualToString:WLWrapContentTypeAuto]) {
            [error show];
        } else {
            [error showIgnoringNetworkError];
        }
		[weakSelf.refresher endRefreshing];
        weakSelf.showLoadingView = NO;
    }];
}

- (void)reloadData {
    [self.groups setCandies:self.wrap.candies];
    if (self.isLive) {
        self.candies = [self.wrap liveCandies];
    }
    self.showLoadingView = YES;
}

- (void)appendDates {
    __weak typeof(self)weakSelf = self;
    if (self.isLive) {
        if (self.candiesRequest.loading) {
            __weak typeof(self)weakSelf = self;
            run_after(0.0f, ^{
                weakSelf.showLoadingView = NO;
            });
            return;
        }
        if (!self.candies.nonempty) {
            [self refreshWrap:WLWrapContentTypeLive];
            return;
        }
        self.candiesRequest = [WLCandiesRequest request:self.wrap];
        self.candiesRequest.newer = [[self.candies firstObject] updatedAt];
        self.candiesRequest.older = [[self.candies lastObject] updatedAt];
        self.candiesRequest.type = WLPaginatedRequestTypeOlder;
        self.candiesRequest.sameDay = YES;
        NSUInteger count = self.candies.count;
        [self.candiesRequest send:^(NSOrderedSet* candies) {
            [weakSelf.candies unionOrderedSet:candies];
            [weakSelf.groups addCandies:candies];
            weakSelf.showLoadingView = weakSelf.candies.count != count;
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
            weakSelf.showLoadingView = NO;
        }];
    } else {
        if (self.wrapRequest.loading) {
            __weak typeof(self)weakSelf = self;
            run_after(0.0f, ^{
                weakSelf.showLoadingView = NO;
            });
            return;
        }
        if (!self.wrap.candies.nonempty) {
            [self refreshWrap:WLWrapContentTypeHistory];
            return;
        }
        self.wrapRequest.page = ((self.groups.set.count + 1)/10 + 1);
        NSUInteger count = self.wrap.candies.count;
        [self.wrapRequest send:^(WLWrap* wrap) {
            [weakSelf.groups addCandies:wrap.candies];
            if (count == wrap.candies.count) {
                weakSelf.showLoadingView = NO;
            }
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
            weakSelf.showLoadingView = NO;
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
            weakSelf.candies = [weakSelf.wrap liveCandies];
            [weakSelf.collectionView reloadData];
        }
    });
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    [self.groups addCandy:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [self.groups removeCandy:candy];
    if (!self.wrap.candies.nonempty) {
        [self setFirstContributorViewHidden:NO animated:self.isOnTopOfNagvigation];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self.groups sort:candy];
    if (self.isLive) {
        [self.candies sortByUpdatedAtDescending];
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

#pragma mark - WLGroupedSetDelegate

- (void)groupedSetGroupsChanged:(WLGroupedSet *)set {
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

- (IBAction)tabChanged:(SegmentedControl *)sender {
    [self changeViewTab:sender.selectedSegment];
}

- (void)changeViewTab:(WLWrapViewTab)viewTab {
    self.viewTab = viewTab;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.viewTab) forKey:WLWrapViewDefaultTabKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self didChangeViewTab];
}

- (void)didChangeViewTab {
    if (self.isLive) {
        self.candies = [self.wrap liveCandies];
    }
    self.showLoadingView = YES;
    self.collectionView.contentOffset = CGPointZero;
}

#pragma mark - WLCandiesCellDelegate

- (void)presentCandy:(WLCandy*)candy {
    if ([candy isImage]) {
        NSMutableArray* controllers = [[self.navigationController viewControllers] mutableCopy];
		WLCandyViewController *candyController = [WLCandyViewController instantiate];
        candyController.backViewController = self;
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
        return self.isLive ? [self.candies count] : [self.groups.set count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString* wrapCellIdentifier = @"WLWrapCell";
        WLWrapCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:wrapCellIdentifier forIndexPath:indexPath];
        cell.item = self.wrap;
        cell.delegate = self;
        cell.tabControl.selectedSegment = self.viewTab;
        return cell;
    } else if (self.isLive) {
        WLCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCandyCellIdentifier forIndexPath:indexPath];
        WLCandy* candy = [self.candies tryObjectAtIndex:indexPath.item];
        cell.item = candy;
        cell.delegate = self;
        return cell;
    } else {
        WLCandiesCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLCandiesCell reuseIdentifier] forIndexPath:indexPath];
        WLGroup* date = [self.groups.set tryObjectAtIndex:indexPath.item];
        cell.item = date;
        cell.delegate = self;
        if (indexPath.row > 0) {
            cell.refreshable = NO;
        } else {
            cell.refreshable = [date.name isEqualToString:[[NSDate serverTime] stringWithFormat:self.groups.dateFormat]];
        }
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
    return (section == 0 || !self.showLoadingView) ? CGSizeZero : CGSizeMake(collectionView.width, 60);
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

#pragma mark - WLWrapCellDelegate

- (void)wrapCell:(WLWrapCell *)cell didDeleteOrLeaveWrap:(WLWrap *)wrap {
    [[WLWrapBroadcaster broadcaster] removeReceiver:self];
    [self.navigationController popViewControllerAnimated:YES];
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
