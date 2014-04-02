//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLHomeViewController.h"
#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "StreamView.h"
#import "WLWrapDataViewController.h"
#import "UIColor+CustomColors.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLComment.h"
#import "UIImage+WLStoring.h"
#import "WLCandy.h"
#import "WLWrapCandyCell.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, WLCameraViewControllerDelegate, StreamViewDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet StreamView *topWrapStreamView;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapCreatedAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapAuthorsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;
@property (strong, nonatomic) NSArray* wraps;
@property (strong, nonatomic) WLWrap* topWrap;
@property (nonatomic) BOOL loading;
@property (strong, nonatomic) IBOutlet UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *footerSpinner;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.composeContainer.hidden = YES;
	self.noWrapsView.hidden = YES;
	self.loading = NO;
	[self fetchWraps];
	
}

- (void)fetchWraps {
	if (self.loading || self.tableView.tableFooterView == nil) {
		return;
	}
	self.loading = YES;
	NSInteger page = ((self.wraps.count + 1)/10 + 1);
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] wrapsWithPage:page success:^(NSArray * object) {
		
		[weakSelf validateFooterWithObjectsCount:object.count];
		if (page == 1) {
			weakSelf.wraps = object;
		}
		else {
			[weakSelf appendWraps:object];
		}
		weakSelf.loading = NO;
	} failure:^(NSError *error) {
		weakSelf.loading = NO;
	}];
}

- (void) validateFooterWithObjectsCount:(int)count {
	if (count < 10 || count == 0) {
		self.tableView.tableFooterView = nil;
	} else if (self.tableView.tableFooterView == nil) {
		self.tableView.tableFooterView = self.tableFooterView;;
	}
}

- (void)setTopWrap:(WLWrap *)topWrap {
	_topWrap = topWrap;
	[self updateHeaderViewWithWrap:topWrap];
}

- (void)setWraps:(NSArray *)wraps {
	wraps = [wraps sortedEntries];
	WLWrap* topWrap = [wraps firstObject];
	_wraps = [wraps arrayByRemovingObject:topWrap];
	self.composeContainer.hidden = (topWrap == nil);
	self.noWrapsView.hidden = (topWrap != nil);
	self.topWrap = topWrap;
	[self.tableView reloadData];
}

- (void)updateHeaderViewWithWrap:(WLWrap*)wrap {
	self.headerWrapNameLabel.text = wrap.name;
	self.headerWrapCreatedAtLabel.text = [wrap.createdAt stringWithFormat:@"MMMM dd, yyyy"];
	__weak typeof(self)weakSelf = self;
	[wrap contributorNames:^(NSString *names) {
		weakSelf.headerWrapAuthorsLabel.text = names;
	}];
	self.headerView.height = [wrap.candies count] > 2 ? 212 : 106;
	self.tableView.tableHeaderView = self.headerView;
	[self.topWrapStreamView reloadData];
	
	[[WLAPIManager instance] candies:wrap success:^(id object) {
		
	} failure:^(NSError *error) {
		
	}];
}

- (void)appendWraps: (id)object {
	_wraps = [_wraps arrayByAddingObjectsFromArray:object];
	[self.tableView reloadData];
}

- (IBAction)typeMessage:(UIButton *)sender {
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	WLWrap* topWrap = self.topWrap;
	WLCandy* conversation = [topWrap actualConversation];
	[conversation addCommentWithText:text];
	[self updateHeaderViewWithWrap:topWrap];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapSegue]) {
		WLWrap* wrap = [self.wraps objectAtIndex:[self.tableView indexPathForSelectedRow].row];
		[(WLWrapViewController* )segue.destinationViewController setWrap:wrap];
	} else if ([segue isTopWrapSegue]) {
		[(WLWrapViewController* )segue.destinationViewController setWrap:self.topWrap];
	} else if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.delegate = self;
		cameraController.mode = WLCameraModeFullSize;
		cameraController.backfacingByDefault = YES;
	}
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self.composeContainer setEditing:NO animated:YES];
	[self sendMessageWithText:text];
}

- (void)composeBarDidReturn:(WLComposeBar *)composeBar {
	[self.composeContainer setEditing:NO animated:YES];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLWrapCell";
	WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.wraps objectAtIndex:(indexPath.row)];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [tableView dequeueReusableCellWithIdentifier:@"LabelCell"];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.composeContainer.editing) {
		[self.composeContainer setEditing:NO animated:YES];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat maxOffset = (scrollView.contentSize.height - scrollView.frame.size.height);
	if (!self.loading  && scrollView.contentSize.height > scrollView.frame.size.height && scrollView.contentOffset.y >= maxOffset) {
		[self fetchWraps];
	}
}

#pragma mark - <WLCameraViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[image storeAsImage:^(NSString *path) {
		WLCandy* candy = [WLCandy entry];
		candy.type = WLCandyTypeImage;
		candy.picture.large = path;
		[[WLAPIManager instance] addCandy:candy toWrap:weakSelf.topWrap success:^(id object) {
			
		} failure:^(NSError *error) {
			
		}];
	}];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfColumns:(StreamView *)streamView {
	return 3;
}

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
	if ([self.topWrap.candies count] > 2) {
		return 5;
	} else {
		return 2;
	}
}

- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item {
	if (item.index.row < [self.topWrap.candies count]) {
		WLWrapCandyCell* candyView = [streamView reusableViewOfClass:[WLWrapCandyCell class]
															 forItem:item
														 loadingType:StreamViewReusableViewLoadingTypeNib];
		candyView.item = [self.topWrap.candies objectAtIndex:item.index.row];
		return candyView;
	} else {
		UILabel* placeholderLabel = [streamView reusableViewOfClass:[UILabel class]
															forItem:item
														loadingType:StreamViewReusableViewLoadingTypeInit];
		placeholderLabel.backgroundColor = [UIColor WL_grayColor];
		return placeholderLabel;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (CGFloat)streamView:(StreamView *)streamView initialRangeForColumn:(NSInteger)column {
	return column == 1 ? 106 : 0;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row < [self.topWrap.candies count]) {
		WLWrapDataViewController* controller = [self.storyboard wrapDataViewController];
		controller.candy = [self.topWrap.candies objectAtIndex:item.index.row];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
