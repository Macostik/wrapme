//
//  WLWrapDataViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyViewController.h"
#import "WLCommentCell.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "WLComposeContainer.h"
#import "WLComposeBar.h"
#import "WLComment.h"
#import "WLSession.h"
#import "WLAPIManager.h"
#import "WLWrap.h"
#import "WLWrapDate.h"
#import "UIFont+CustomFonts.h"
#import "WLRefresher.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIStoryboard+Additions.h"
#import "WLImageViewController.h"
#import "UIScrollView+Additions.h"
#import "WLKeyboardBroadcaster.h"
#import "WLDataManager.h"
#import "NSDate+Additions.h"
#import "WLWrapBroadcaster.h"
#import "WLWrapChannelBroadcaster.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "WLEntryState.h"

static NSString* WLCommentCellIdentifier = @"WLCommentCell";

@interface WLCandyViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver, WLWrapChannelBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;
@property (weak, nonatomic) IBOutlet UIView *contentIndicatorView;

@property (weak, nonatomic) WLRefresher *refresher;

@property (strong, nonatomic) WLWrapDate* date;

@property (nonatomic) BOOL shouldLoadMoreCandies;

@property (nonatomic) BOOL loading;

@property (strong, nonatomic) WLWrapChannelBroadcaster* wrapChannelBroadcaster;



@end

@implementation WLCandyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.contentIndicatorView.layer.cornerRadius = 2;

	self.composeBarView.placeholder = @"Write your comment ...";
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refresh];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
	
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	
	[self showContentIndicatorView:NO];
}

- (WLWrapChannelBroadcaster *)wrapChannelBroadcaster {
	if (!_wrapChannelBroadcaster) {
		_wrapChannelBroadcaster = [[WLWrapChannelBroadcaster alloc] initWithReceiver:self];
	}
	return _wrapChannelBroadcaster;
}

- (UIView *)swipeView {
	return self.tableView;
}

- (void)setWrap:(WLWrap *)wrap candy:(WLCandy *)candy {
	self.wrap = wrap;
	self.wrapChannelBroadcaster.wrap = wrap;
	__weak typeof(self)weakSelf = self;
	[wrap enumerateCandies:^(WLCandy *_candy, WLWrapDate *date, BOOL *stop) {
		if (_candy.type == WLCandyTypeImage) {
			if ([_candy isEqualToEntry:candy]) {
				weakSelf.date = date;
				weakSelf.shouldLoadMoreCandies = [weakSelf.date.candies count] % WLAPIGeneralPageSize == 0;
				[weakSelf setItems:[date images] currentItem:_candy];
				*stop = YES;
			}
		}
	}];
}

- (void)setCandy:(WLCandy *)candy  {
	self.item = candy;
}

- (WLCandy *)candy {
	return self.item;
}

- (void)didSwipeLeft {
	[super didSwipeLeft];
	[self showContentIndicatorView:YES];
}

- (void)didSwipeRight {
	[super didSwipeRight];
	[self showContentIndicatorView:YES];
}

- (void)showContentIndicatorView:(BOOL)animated {
	if ([self.items count] > 1) {
		CGFloat contentRatio = ((CGFloat)[self.items indexOfObject:self.item]) / ((CGFloat)[self.items count] - 1.0f);
		CGFloat x = (self.view.width - self.contentIndicatorView.width - 2) * contentRatio;
		if (animated) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationBeginsFromCurrentState:YES];
		}
		self.contentIndicatorView.alpha = 1.0f;
		self.contentIndicatorView.x = x + 1;
		if (animated) {
			[UIView commitAnimations];
		}
	}
	[UIView cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideContentIndicatorView) object:nil];
	[self performSelector:@selector(hideContentIndicatorView) withObject:nil afterDelay:1.0f];
}

- (void)hideContentIndicatorView {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	self.contentIndicatorView.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)willShowItem:(id)item {
	[self setupImage];
	[self refresh];
	
	__weak typeof(self)weakSelf = self;
	if (!self.loading && [self.items lastObject] == item && self.shouldLoadMoreCandies) {
		self.loading = YES;
		[[WLAPIManager instance] candies:self.wrap date:self.date success:^(id object) {
			weakSelf.shouldLoadMoreCandies = ([object count] == WLAPIGeneralPageSize);
			weakSelf.date.candies = (id)[weakSelf.date.candies arrayByAddingObjectsFromArray:object];
			weakSelf.items = [weakSelf.date images];
			weakSelf.loading = NO;
			[weakSelf showContentIndicatorView:NO];
		} failure:^(NSError *error) {
			weakSelf.shouldLoadMoreCandies = NO;
			[error showIgnoringNetworkError];
			weakSelf.loading = NO;
		}];
	}
}

- (NSUInteger)repairedCurrentIndex {
	NSArray* items = self.items;
	for (WLCandy* candy in items) {
		if ([candy isEqualToEntry:self.candy]) {
			return [items indexOfObject:candy];
		}
	}
	return NSNotFound;
}

- (void)refresh {
	if (self.candy.uploading == nil) {
		__weak typeof(self)weakSelf = self;
		[WLDataManager candy:self.candy wrap:self.wrap success:^(id object, BOOL cached, BOOL stop) {
			[weakSelf setupImage];
			[weakSelf.refresher endRefreshing];
		} failure:^(NSError *error) {
			[error showIgnoringNetworkError];
			[weakSelf.refresher endRefreshing];
		}];
	}
}

- (void)setupImage {
	WLCandy* image = self.candy;
	self.wrapChannelBroadcaster.candy = image;
	__weak typeof(self)weakSelf = self;
	if (!self.spinner.isAnimating) {
		[self.spinner startAnimating];
	}
	[self.imageView setUrl:image.picture.medium completion:^(UIImage* image, BOOL cached, NSError* error) {
		if (weakSelf.spinner.isAnimating) {
			[weakSelf.spinner stopAnimating];
		}
	}];
	self.dateLabel.text = [NSString stringWithFormat:@"Posted %@", WLString(image.createdAt.timeAgoString)];
	self.titleLabel.text = [NSString stringWithFormat:@"By %@", WLString(image.contributor.name)];
	[self.tableView reloadData];
	[image setUpdated:NO];
}

- (CGFloat)calculateTableHeight {
	return (self.view.height - self.composeBarView.height - self.topView.height);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isImageSegue]) {
		WLImageViewController* controller = segue.destinationViewController;
		controller.image = self.candy;
	}
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentRemoved:(WLComment *)comment {
	[self.tableView reloadData];
}

#pragma mark - WLWrapChannelBroadcastReceiver

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didAddCandy:(WLCandy *)candy {
	[candy setUpdated:NO];
}

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didAddComment:(WLCandy *)candy {
	self.candy = [self.candy updateWithObject:candy];
}

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didDeleteCandy:(WLCandy *)candy {
	[WLToast showWithMessage:@"This candy is no longer avaliable."];
	self.items = [self.items entriesByRemovingEntry:candy];
	if (self.items.nonempty) {
		self.candy = [self.items lastObject];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didDeleteComment:(WLCandy *)candy {
	[self setupImage];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
	self.containerView.height = self.view.height - self.topView.height;
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber*)keyboardHeight {
	self.containerView.height = self.view.height - self.topView.height - [keyboardHeight floatValue];
	[self.tableView scrollToBottomAnimated:YES];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
	WLComment* comment = [WLComment commentWithText:text];
	[[WLAPIManager instance] addComment:comment candy:self.candy wrap:self.wrap success:^(id object) {
		[weakSelf.tableView reloadData];
		[weakSelf.wrap broadcastChange];
		[weakSelf.tableView scrollToBottomAnimated:YES];
	} failure:^(NSError *error) {
		[error show];
	}];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
	[self changeDimentionsWithComposeBar:composeBar];
}

- (void)changeDimentionsWithComposeBar:(WLComposeBar *)composeBar {
	self.composeBarView.height = composeBar.height;
	self.tableView.height = self.containerView.height - self.composeBarView.height;
	self.composeBarView.y = self.tableView.y + self.tableView.height;
	[self.tableView scrollToBottomAnimated:YES];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return YES;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	NSString* cellIdentifier = WLCommentCellIdentifier;
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.item = comment;
	cell.wrap = self.wrap;
	cell.candy = self.candy;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
														 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WLCommentCell commentFont]} context:nil].size.height);
	CGFloat cellHeight = (commentHeight + WLAuthorLabelHeight);
	return MAX(WLMinimumCellHeight, cellHeight + 10);
}

@end
