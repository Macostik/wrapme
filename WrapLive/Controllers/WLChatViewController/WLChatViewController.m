//
//  WLChatViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChatViewController.h"
#import "WLWrap.h"
#import "WLAPIManager.h"
#import "WLRefresher.h"
#import "WLMessageCell.h"
#import "WLCandy.h"
#import "WLUser.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"
#import "UIView+Shorthand.h"
#import "WLLoadingView.h"
#import "WLMessageGroupCell.h"
#import "NSDate+Formatting.h"
#import "NSObject+NibAdditions.h"
#import "WLCollectionViewFlowLayout.h"
#import "UIScrollView+Additions.h"
#import "WLKeyboardBroadcaster.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLBlocks.h"
#import "WLWrapBroadcaster.h"
#import "WLGroupedSet.h"
#import "WLSignificantTimeBroadcaster.h"

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver>

@property (nonatomic, strong) WLGroupedSet* groups;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (nonatomic) CGFloat keyboardHeight;

@property (weak, nonatomic) id operation;

@end

@implementation WLChatViewController

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.groups = [[WLGroupedSet alloc] init];
    self.groups.singleMessage = NO;
    self.groups.dateFormat = @"MMM d, yyyy";
	
	if (self.wrap.name.nonempty) {
		self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(self.wrap.name)];
	} else {
		__weak typeof(self)weakSelf = self;
		[self.wrap fetch:^(WLWrap *wrap) {
			weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(wrap.name)];
		} failure:^(NSError *error) {
		}];
	}
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshMessages) colorScheme:WLRefresherColorSchemeOrange];
	self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
	self.composeBar.placeholder = @"Write your message ...";
	
	run_getting_object(^id{
		return [weakSelf.wrap messages];
	}, ^(id object) {
		[weakSelf setMessages:object];
		[weakSelf loadMessages:nil];
	});
	
	self.backSwipeGestureEnabled = YES;
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.shouldShowKeyboard) {
		[self.composeBar becomeFirstResponder];
	}
}

- (void)setShouldAppendMoreMessages:(BOOL)shouldAppendMoreMessages {
	_shouldAppendMoreMessages = shouldAppendMoreMessages;
	if (shouldAppendMoreMessages) {
		self.layout.loadingView = [WLLoadingView instance];
	} else {
		self.layout.loadingView = nil;
	}
}

- (void)setMessages:(NSOrderedSet*)messages {
    [self.groups setCandies:messages];
    [self.groups sort];
    [self.collectionView reloadData];
}

- (void)addMessages:(NSOrderedSet*)messages {
    [self.groups addCandies:messages];
    [self.groups sort];
	[self.collectionView reloadData];
}

- (void)insertMessage:(WLCandy*)message {
	[self.groups addCandy:message];
    [self.groups sort];
    [self.collectionView reloadData];
}

- (void)refreshMessages {
	__weak typeof(self)weakSelf = self;
    WLGroup* group = [self.groups.set firstObject];
    WLCandy* candy = [group.entries firstObject];
    if (!candy) {
        [self loadMessages:^{
            [weakSelf.refresher endRefreshing];
        }];
        return;
    }
    self.operation = [self.wrap messagesNewer:candy.updatedAt success:^(NSOrderedSet *messages) {
        weakSelf.shouldAppendMoreMessages = ([messages count] == WLAPIPageSize);
		[weakSelf addMessages:messages];
		[weakSelf.refresher endRefreshing];
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
		[weakSelf.refresher endRefreshing];
    }];
}

- (void)loadMessages:(WLBlock)completion {
    __weak typeof(self)weakSelf = self;
    self.operation = [self.wrap messages:^(NSOrderedSet *messages) {
        weakSelf.shouldAppendMoreMessages = ([messages count] == WLAPIPageSize);
		[weakSelf setMessages:messages];
        if (completion) {
            completion();
        }
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
        if (completion) {
            completion();
        }
    }];
}

- (void)appendMessages {
	if (self.operation) return;
	__weak typeof(self)weakSelf = self;
    WLGroup* group = [self.groups.set lastObject];
    WLCandy* candy = [group.entries lastObject];
	self.operation = [self.wrap messagesOlder:candy.updatedAt success:^(id object) {
		weakSelf.shouldAppendMoreMessages = ([object count] == WLAPIPageSize);
		[weakSelf addMessages:object];
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreMessages = NO;
		[error showIgnoringNetworkError];
	}];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    if ([candy isMessage]) {
        candy.unread = @NO;
        [self insertMessage:candy];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    if ([candy isMessage]) {
        [self setMessages:[self.wrap messages]];
        [self.collectionView reloadData];
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    if ([candy isMessage]) {
        for (WLGroup* group in self.groups.set) {
            if ([group.entries containsObject:candy] && ![group.date isSameDay:candy.updatedAt]) {
                [group.entries removeObject:candy];
                if (![group.entries count]) {
                    [self.groups.set removeObject:group];
                    break;
                }
            }
        }
        [self.groups addCandy:candy];
        [self.groups sort];
        [self.collectionView reloadData];
    }
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.wrap;
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
	self.keyboardHeight = 0;
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self.collectionView reloadData];
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
	self.keyboardHeight = [keyboardHeight floatValue];
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height - self.keyboardHeight;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self.collectionView reloadData];
}

#pragma mark - WlSignificantTimeBroadcasterReceiver

- (void)broadcaster:(WLSignificantTimeBroadcaster *)broadcaster didChangeSignificantTime:(id)object {
    [self setMessages:[self.wrap messages]];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    if (self.wrap.valid) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    __weak typeof(self)weakSelf = self;
    [self.wrap uploadMessage:text success:^(WLCandy *candy) {
        [weakSelf insertMessage:candy];
		[weakSelf.collectionView scrollToTopAnimated:YES];
    } failure:^(NSError *error) {
		[error show];
    }];
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
	[self changeDimentionsWithComposeBar:composeBar];
}

- (void)changeDimentionsWithComposeBar:(WLComposeBar *)composeBar {
	self.composeBar.height = composeBar.height;
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height - self.keyboardHeight;
	self.composeBar.y = self.collectionView.height + self.topView.height;
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return YES;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return [self.groups.set count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLGroup* group = [self.groups.set tryObjectAtIndex:section];
	return [group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLGroup* group = [self.groups.set tryObjectAtIndex:indexPath.section];
	WLCandy* message = [group.entries objectAtIndex:indexPath.row];
    message.unread = @NO;
	BOOL isMyComment = [message.contributor isCurrentUser];
	NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
	WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.item = message;
	[self handlePaginationWithIndexPath:indexPath];
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
	groupCell.group = [self.groups.set tryObjectAtIndex:indexPath.section];
	return groupCell;
}

- (CGFloat)heightOfMessageCell:(WLCandy *)comment {
	CGFloat commentHeight  = ceilf([comment.message boundingRectWithSize:CGSizeMake(250, CGFLOAT_MAX)
																	 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
	commentHeight += 2*WLMessageAuthorLabelHeight;
	return MAX(WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLGroup* group = [self.groups.set tryObjectAtIndex:indexPath.section];
	WLCandy* message = [group.entries tryObjectAtIndex:indexPath.row];
	return CGSizeMake(collectionView.frame.size.width, [self heightOfMessageCell:message]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
	if (section < [self.groups.set count]) {
		return CGSizeMake(collectionView.frame.size.width, 32);
	} else {
		return CGSizeZero;
	}
}

- (void)handlePaginationWithIndexPath:(NSIndexPath*)indexPath {
	if (!self.shouldAppendMoreMessages) {
		return;
	}
    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:indexPath.section];
	if (indexPath.section == numberOfSections - 1 && indexPath.item == numberOfItems - 1) {
		[self appendMessages];
	}
}

@end
