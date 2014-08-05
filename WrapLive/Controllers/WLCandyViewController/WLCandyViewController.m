//
//  WLWrapDataViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "MFMailComposeViewController+Additions.h"
#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import "NSString+Additions.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UIFont+CustomFonts.h"
#import "UIScrollView+Additions.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLCandiesRequest.h"
#import "WLCandy.h"
#import "WLCandyViewController.h"
#import "WLComment.h"
#import "WLCommentCell.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLGroupedSet.h"
#import "WLImageFetcher.h"
#import "WLImageViewController.h"
#import "WLKeyboardBroadcaster.h"
#import "WLNavigation.h"
#import "WLProgressBar.h"
#import "WLRefresher.h"
#import "WLSession.h"
#import "WLToast.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLWrapBroadcaster.h"
#import "WLInternetConnectionBroadcaster.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLWrap+Extended.h"

static NSString* WLCommentCellIdentifier = @"WLCommentCell";

@interface WLCandyViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver, MFMailComposeViewControllerDelegate, WLProgressBarDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftArrow;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *contentIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;
@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (nonatomic) BOOL autoenqueueUploading;
@property (nonatomic) BOOL shouldLoadMoreCandies;
@property (strong, nonatomic) NSOrderedSet* comments;
@property (strong, nonatomic) WLToast* dateChangeToast;
@property (weak, nonatomic) WLRefresher *refresher;

@end

@implementation WLCandyViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if (!self.groups) {
        self.groups = [WLGroupedSet groupsOrderedBy:self.orderBy];
        [self.groups addCandies:[self.candy.wrap images]];
        self.group = [self.groups groupWithCandy:self.candy];
    }
    
	self.contentIndicatorView.layer.cornerRadius = 2;

	self.composeBarView.placeholder = @"Write your comment ...";
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView target:self action:@selector(refresh) colorScheme:WLRefresherColorSchemeOrange];
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
	
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
    
    [[WLInternetConnectionBroadcaster broadcaster] addReceiver:self];
	
	[self showContentIndicatorView:NO];
    
    [self fetchOlder];
}

- (void)setGroup:(WLGroup *)group {
    _group = group;
    self.items = [[group.entries selectObjects:^BOOL(id item) {
        return [item isImage];
    }] mutableCopy];
    if (![self.items containsObject:self.item]) {
        self.item = [self.items firstObject];
    }
}

- (UIView *)swipeView {
	return self.tableView;
}

- (void)setCandy:(WLCandy *)candy {
    [self setItems:nil currentItem:candy];
}

- (WLCandy *)candy {
	return self.item;
}

- (void)fetchNewer {
    WLCandy* candy = self.candy;
    if (!self.group.request.loading && [self.items indexOfObject:candy] < 3) {
        self.group.request.type = WLPaginatedRequestTypeNewer;
        [self fetchCandies];
    }
}

- (void)fetchOlder {
    WLCandy* candy = self.candy;
    NSUInteger count = [self.items count];
    NSUInteger index = [self.items indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (!self.group.request.loading && shouldAppendCandies) {
        self.group.request.type = WLPaginatedRequestTypeOlder;
        [self fetchCandies];
    }
}

- (void)fetchCandies {
    __weak typeof(self)weakSelf = self;
    [self.group send:^(NSOrderedSet *candies) {
        if (candies.nonempty) {
            WLCandy* candy = weakSelf.candy;
            [weakSelf.items unionOrderedSet:[candies selectObjects:^BOOL(WLCandy* item) {
                return [item isImage] && [item.updatedAt isSameDay:candy.updatedAt];
            }]];
            [weakSelf.items sortByUpdatedAtDescending];
        }
    } failure:^(NSError *error) {
        if (error.isNetworkError) {
            weakSelf.group.completed = YES;
        }
    }];
}

- (void)didSwipeLeft:(NSUInteger)currentIndex {
    if (self.group.completed && self.candy == [self.items lastObject]) {
        
        NSUInteger (^increment)(NSUInteger index) = ^NSUInteger (NSUInteger index) {
            return index + 1;
        };
        
        if ([self swipeToGroupAtIndex:increment([self.groups.set indexOfObject:self.group]) operationBlock:increment]) {
            [[self swipeView] leftPush];
            [self onDateChanged];
        }
    } else {
        [super didSwipeLeft:currentIndex];
        [self fetchOlder];
    }
    [self showContentIndicatorView:YES];
}

- (void)didSwipeRight:(NSUInteger)currentIndex {
    if (self.candy == [self.items firstObject]) {
        
        NSUInteger (^decrement)(NSUInteger index) = ^NSUInteger (NSUInteger index) {
            return index - 1;
        };
        
        if ([self swipeToGroupAtIndex:decrement([self.groups.set indexOfObject:self.group]) operationBlock:decrement]) {
            [[self swipeView] rightPush];
            [self onDateChanged];
        }
    } else {
        [super didSwipeRight:currentIndex];
    }
    [self showContentIndicatorView:YES];
}

- (WLToast *)dateChangeToast {
    if (!_dateChangeToast) {
        _dateChangeToast = [[WLToast alloc] init];
    }
    return _dateChangeToast;
}

- (void)onDateChanged {
    WLToastAppearance* appearance = [WLToastAppearance appearance];
    appearance.shouldShowIcon = NO;
    appearance.height = 44;
    appearance.contentMode = UIViewContentModeCenter;
    appearance.backgroundColor = [UIColor colorWithRed:0.953 green:0.459 blue:0.149 alpha:0.75];
    [self.dateChangeToast showWithMessage:self.group.name appearance:appearance inView:self.containerView];
    self.rightArrow.hidden = NO;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.25f delay:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        weakSelf.rightArrow.alpha = 0.0f;
        weakSelf.rightArrow.transform = CGAffineTransformMakeTranslation(44, 0);
    } completion:^(BOOL finished) {
        weakSelf.rightArrow.hidden = YES;
        weakSelf.rightArrow.alpha = 1.0f;
        weakSelf.rightArrow.transform = CGAffineTransformIdentity;
    }];
}

- (BOOL)swipeToGroupAtIndex:(NSUInteger)index operationBlock:(NSUInteger (^)(NSUInteger index))operationBlock {
    if ([self.groups.set containsIndex:index]) {
        WLGroup* group = [self.groups.set objectAtIndex:index];
        if ([group hasAtLeastOneImage]) {
            self.group = group;
            return YES;
        } else {
            return [self swipeToGroupAtIndex:operationBlock(index) operationBlock:operationBlock];
        }
    }
    return NO;
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

- (void)refresh {
	if (self.candy.uploaded) {
		__weak typeof(self)weakSelf = self;
        [self.candy fetch:^(id object) {
            [weakSelf setupImage];
			[weakSelf.refresher endRefreshing];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
			[weakSelf.refresher endRefreshing];
        }];
	} else {
        [self.refresher endRefreshing];
    }
}

- (void)setupImage {
	WLCandy* image = self.candy;
	__weak typeof(self)weakSelf = self;
    
    if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
        self.progressBar.progress = .2f;
    } else {
        self.progressBar.operation = self.candy.uploading.operation;
        self.progressBar.operation.completionBlock = ^ {
            weakSelf.progressBar.hidden = YES;
        };
    }
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
    self.progressBar.hidden = image.uploading.operation ? image.uploading.operation.isFinished : image.uploaded;
	[self reloadComments];
    image.unread = @NO;
//    self.leftArrow.hidden = image == [self.items firstObject];
//    self.rightArrow.hidden = image == [self.items lastObject];
}

- (void)reloadComments {
    self.comments = self.candy.comments;
    [self.tableView reloadData];
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

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self setupImage];
    
    if (self.autoenqueueUploading) {
        self.autoenqueueUploading = NO;
        for (WLComment* comment in candy.comments) {
            if (!comment.uploaded) {
                [WLUploading enqueueAutomaticUploading:^{
                }];
                break;
            }
        }
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentRemoved:(WLComment *)comment {
	[self reloadComments];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [WLToast showWithMessage:@"This candy is no longer avaliable."];
    NSUInteger index = [self.items indexOfObject:candy];
    if (index != NSNotFound) {
        [self.items removeObject:candy];
        if (self.items.nonempty) {
             if ([self.items containsIndex:index - 1]) {
                self.item = [self.items objectAtIndex:index - 1];
             } else if ([self.items containsIndex:index + 1]) {
                 self.item = [self.items objectAtIndex:index + 1];
             } else {
                self.item = [self.items firstObject];
            }
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
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
	self.containerView.height = self.view.height - self.containerView.y;
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber*)keyboardHeight {
	self.containerView.height = self.view.height - self.containerView.y - [keyboardHeight floatValue];
	[self.tableView scrollToBottomAnimated:YES];
}

#pragma mark - WLInternetConnectionBroadcaster

- (void)broadcaster:(WLInternetConnectionBroadcaster *)broadcaster internetConnectionReachable:(NSNumber *)reachable {
    if (reachable.intValue == NotReachable) {
        run_in_main_queue(^{
            self.progressBar.progress = .2f;
        });
    }
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    WLCandy* candy = self.candy;
    if (candy.valid && candy.wrap.valid) {
        if (self.backViewController) {
            [self.navigationController popToViewController:self.backViewController animated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)report:(UIButton *)sender {
    WLCandy* candy = self.candy;
    if ([candy.contributor isCurrentUser] || [candy.wrap.contributor isCurrentUser]) {
        [UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" completion:^(NSUInteger index) {
            if (index == 0) {
                [candy remove:^(id object) {
                    [WLToast showWithMessage:@"Candy was deleted successfully."];
                } failure:^(NSError *error) {
                }];
            }
        }];
    } else {
        [UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Report as inappropriate" completion:^(NSUInteger index) {
            if (index == 0) {
                [MFMailComposeViewController messageWithCandy:candy];
            }
        }];
    }
}

- (void)sendMessageWithText:(NSString*)text {
    self.autoenqueueUploading = !self.candy.uploaded;
	__weak typeof(self)weakSelf = self;
     [self.candy uploadComment:text success:^(WLComment *comment) {
        [weakSelf reloadComments];
    } failure:^(NSError *error) {
    }];
    [self reloadComments];
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
	return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.comments objectAtIndex:indexPath.row];
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
	cell.item = comment;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.comments objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
														 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WLCommentCell commentFont]} context:nil].size.height);
	CGFloat cellHeight = (commentHeight + WLAuthorLabelHeight);
	return MAX(WLMinimumCellHeight, cellHeight + 10);
}

@end
