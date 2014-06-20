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
#import "WLDate.h"
#import "UIFont+CustomFonts.h"
#import "WLRefresher.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLNavigation.h"
#import "WLImageViewController.h"
#import "UIScrollView+Additions.h"
#import "WLKeyboardBroadcaster.h"
#import "WLDataManager.h"
#import "NSDate+Additions.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "UIAlertView+Blocks.h"
#import "MFMailComposeViewController+Additions.h"
#import "UIActionSheet+Blocks.h"

static NSString* WLCommentCellIdentifier = @"WLCommentCell";

@interface WLCandyViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver, MFMailComposeViewControllerDelegate>

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

@property (nonatomic) BOOL shouldLoadMoreCandies;

@property (weak, nonatomic) IBOutlet UIButton *reportButton;

@property (strong, nonatomic) NSMutableOrderedSet* candies;

@end

@implementation WLCandyViewController
{
    BOOL canFetchNewer:YES;
    BOOL canFetchOlder:YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.contentIndicatorView.layer.cornerRadius = 2;

	self.composeBarView.placeholder = @"Write your comment ...";
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView target:self action:@selector(refresh) colorScheme:WLRefresherColorSchemeOrange];
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
	
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	
	[self showContentIndicatorView:NO];
}

- (NSMutableOrderedSet *)candies {
    if (!_candies) {
        _candies = [NSMutableOrderedSet orderedSet];
    }
    return _candies;
}

- (UIView *)swipeView {
	return self.tableView;
}

- (NSOrderedSet *)items {
    return self.candies;
}

- (void)setCandy:(WLCandy *)candy  {
    [self setItems:nil currentItem:candy];
    self.candies = [NSMutableOrderedSet orderedSetWithObject:candy];
    canFetchNewer = YES;
    canFetchOlder = YES;
    [self fetchNewer];
    [self fetchOlder];
}

- (void)fetchNewer {
    __weak typeof(self)weakSelf = self;
    if (canFetchNewer) {
        canFetchNewer = NO;
        [self.candy newerCandies:NO success:^(NSOrderedSet *candies) {
            if (candies.nonempty) {
                [weakSelf.candies unionOrderedSet:[candies selectObjects:^BOOL(WLCandy* item) {
                    return [item isImage];
                }]];
                [weakSelf.candies sortEntries];
            }
            canFetchNewer = YES;
        } failure:^(NSError *error) {
            [weakSelf.candies unionOrderedSet:[weakSelf.candy.wrap images]];
            [weakSelf.candies sortEntries];
            canFetchNewer = YES;
        }];
    }
}

- (void)fetchOlder {
    __weak typeof(self)weakSelf = self;
    if (canFetchOlder) {
        canFetchOlder = NO;
        [self.candy olderCandies:NO success:^(NSOrderedSet *candies) {
            if (candies.nonempty) {
                [weakSelf.candies unionOrderedSet:[candies selectObjects:^BOOL(WLCandy* item) {
                    return [item isImage];
                }]];
                [weakSelf.candies sortEntries];
            }
            canFetchOlder = YES;
        } failure:^(NSError *error) {
            [weakSelf.candies unionOrderedSet:[weakSelf.candy.wrap images]];
            [weakSelf.candies sortEntries];
            canFetchOlder = YES;
        }];
    }
}

- (WLCandy *)candy {
	return self.item;
}

- (void)didSwipeLeft:(NSUInteger)currentIndex {
	[super didSwipeLeft:currentIndex];
	[self showContentIndicatorView:YES];
    if ([self.candies lastObject] == self.candy) {
		[self fetchOlder];
	}
}

- (void)didSwipeRight:(NSUInteger)currentIndex {
	[super didSwipeRight:currentIndex];
	[self showContentIndicatorView:YES];
    if ([self.candies firstObject] == self.candy) {
		[self fetchNewer];
	}
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
}

- (BOOL)shouldSwipeToItem:(WLCandy*)item {
    return [item isImage];
}

- (NSUInteger)repairedCurrentIndex {
	NSOrderedSet* items = self.items;
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
		[WLDataManager candy:self.candy success:^(id object, BOOL stop) {
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
	__weak typeof(self)weakSelf = self;
	if (!self.spinner.isAnimating) {
		[self.spinner startAnimating];
	}
	[self.imageView setUrl:image.picture.medium completion:^(UIImage* image, BOOL cached, NSError* error) {
		if (weakSelf.spinner.isAnimating) {
			[weakSelf.spinner stopAnimating];
		}
	}];
	self.reportButton.hidden = [self.candy.contributor isCurrentUser];
	self.dateLabel.text = [NSString stringWithFormat:@"Posted %@", WLString(image.createdAt.timeAgoString)];
	self.titleLabel.text = [NSString stringWithFormat:@"By %@", WLString(image.contributor.name)];
	[self.tableView reloadData];
    image.unread = @NO;
}

- (CGFloat)calculateTableHeight {
	return (self.view.height - self.composeBarView.height - self.topView.height);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isImageSegue]) {
		[self.composeBarView endEditing:YES];
		WLImageViewController* controller = segue.destinationViewController;
		controller.image = self.candy;
	}
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentRemoved:(WLComment *)comment {
	[self.tableView reloadData];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [WLToast showWithMessage:@"This candy is no longer avaliable."];
    if (self.items.nonempty) {
        self.item = [self.items firstObject];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.candy.wrap;
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.candy;
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

- (IBAction)report:(UIButton *)sender {
    __weak typeof(self)weakSelf = self;
	[UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Report as inappropriate" completion:^(NSUInteger index) {
		if (index == 0) {
			[MFMailComposeViewController messageWithCandy:weakSelf.candy];
		}
	}];
}

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
    [self.candy uploadComment:text success:^(WLComment *comment) {
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {
        [error show];
    }];
    [weakSelf.tableView reloadData];
    [weakSelf.tableView scrollToBottomAnimated:YES];
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
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
	cell.item = comment;
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
