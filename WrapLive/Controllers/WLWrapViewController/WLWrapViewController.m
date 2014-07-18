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

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLCandiesCellDelegate, WLWrapBroadcastReceiver, UITableViewDataSource, UITableViewDelegate, WLWrapCellDelegate, WLQuickChatViewDelegate, WLGroupedSetDelegate>

@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet WLQuickChatView *quickChatView;

@property (strong, nonatomic) WLGroupedSet* groups;

@property (strong, nonatomic) WLLoadingView* loadingView;

@property (strong, nonatomic) WLWrapRequest* wrapRequest;

@end

@implementation WLWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.wrap.valid) {
        return;
    }
    
    self.groups = [[WLGroupedSet alloc] init];
    self.groups.delegate = self;
    
    self.loadingView = [WLLoadingView instance];
    self.quickChatView.wrap = self.wrap;
    [self refreshWrap];
    self.refresher = [WLRefresher refresherWithScrollView:self.tableView target:self action:@selector(refreshWrap) colorScheme:WLRefresherColorSchemeOrange];
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    [self.groups addCandies:self.wrap.candies];
}

- (void)setLoadingView:(WLLoadingView *)loadingView {
    self.tableView.tableFooterView = loadingView;
}

- (WLLoadingView *)loadingView {
    return (WLLoadingView*)self.tableView.tableFooterView;
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
    NSArray* cells = [[self.tableView visibleCells] selectObjects:^BOOL(id item) {
        return [item isKindOfClass:[WLCandiesCell class]];
    }];
    if (cells.nonempty) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        for (WLCandiesCell* cell in cells) {
            [cell.collectionView reloadData];
        }
    } else {
        [self.tableView reloadData];
    }
}

- (void)refreshWrap {
    self.loadingView.error = NO;
	__weak typeof(self)weakSelf = self;
    self.wrapRequest.page = 1;
    [self.wrapRequest send:^(WLWrap* wrap) {
        [weakSelf reloadData];
        [weakSelf setFirstContributorViewHidden:wrap.candies.nonempty animated:YES];
		[weakSelf.refresher endRefreshing];
        if (!wrap.candies.nonempty) {
            weakSelf.loadingView = nil;
        }
    } failure:^(NSError *error) {
        weakSelf.loadingView.error = YES;
		[error showIgnoringNetworkError];
		[weakSelf.refresher endRefreshing];
    }];
}

- (void)reloadData {
    [self.groups setCandies:self.wrap.candies];
    if ([self.groups.set count] < WLAPIGeneralPageSize) {
        self.loadingView = nil;
    } else {
        self.loadingView = [WLLoadingView instance];
    }
}

- (void)appendDates {
	if (self.wrapRequest.loading || !self.wrap.candies.nonempty) {
		return;
	}
    self.loadingView.error = NO;
	__weak typeof(self)weakSelf = self;
    self.wrapRequest.page = ((self.groups.set.count + 1)/WLAPIGeneralPageSize + 1);
    NSUInteger count = self.wrap.candies.count;
    [self.wrapRequest send:^(WLWrap* wrap) {
        [weakSelf.groups addCandies:wrap.candies];
        if (count == wrap.candies.count) {
            weakSelf.loadingView = nil;
        }
    } failure:^(NSError *error) {
        [error showIgnoringNetworkError];
        weakSelf.loadingView.error = YES;
    }];
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
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    [self.groups addCandy:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [self.groups removeCandy:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self.groups sort:candy];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
    WLWrapCell* cell = (id)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
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
    [self.tableView reloadData];
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

#pragma mark - WLCandiesCellDelegate

- (void)candiesCell:(WLCandiesCell*)cell didSelectCandy:(WLCandy*)candy {
	if ([candy isImage]) {
        NSMutableArray* controllers = [[self.navigationController viewControllers] mutableCopy];
        WLDatesViewController *datesController = [WLDatesViewController instantiate];
        datesController.wrap = self.wrap;
        datesController.dates = self.groups;
        [controllers addObject:datesController];
		WLCandyViewController *candyController = [WLCandyViewController instantiate];
        candyController.backViewController = self;
        [candyController setCandy:candy group:cell.item];
        [controllers addObject:candyController];
        [self.navigationController setViewControllers:controllers animated:YES];
	} else if ([candy isMessage]) {
		[self openChat];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : [self.groups.set count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString* wrapCellIdentifier = @"WLWrapCell";
        WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier forIndexPath:indexPath];
        cell.item = self.wrap;
        cell.delegate = self;
        return cell;
    } else {
        WLCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLCandiesCell reuseIdentifier]];
        WLGroup* date = [self.groups.set tryObjectAtIndex:indexPath.row];
        cell.item = date;
        cell.delegate = self;
        if (indexPath.row > 0) {
            cell.refreshable = NO;
        } else {
            cell.refreshable = [date.name isEqualToString:[[NSDate date] stringWithFormat:self.groups.dateFormat]];
        }
        if (date == [self.groups.set lastObject] && self.tableView.tableFooterView != nil) {
            [self appendDates];
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0) ? 60 : (tableView.width/2.5 + 28);
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
