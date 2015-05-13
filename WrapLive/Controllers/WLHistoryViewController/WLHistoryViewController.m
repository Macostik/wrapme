//
//  WLHistoryViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHistoryViewController.h"
#import "WLButton.h"
#import "WLTextView.h"
#import "WLLabel.h"
#import "WLIconButton.h"
#import "WLEntryStatusIndicator.h"
#import "WLHintView.h"
#import "UIView+AnimationHelper.h"
#import "UITextView+Aditions.h"
#import "WLToast.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLCandyViewController.h"
#import "WLNavigationHelper.h"

@interface WLHistoryViewController ()

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet WLIconButton *actionButton;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *commentIndicator;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *candyIndicator;

@property (weak, nonatomic) WLComment *lastComment;

@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLTextView *lastCommentTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewContstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSMapTable *cachedCandyViewControllers;

@property (nonatomic) NSUInteger currentCandyIndex;

@end

@implementation WLHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lastCommentTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    self.lastCommentTextView.textContainer.maximumNumberOfLines = 2;
    self.lastCommentTextView.textContainerInset = UIEdgeInsetsZero;
    self.lastCommentTextView.textContainer.lineFragmentPadding = .0;
    [self.avatarImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    
    if (!_wrap) {
        _wrap = _candy.wrap;
    }
    
    if (!_history && _wrap) {
        _history = [WLHistory historyWithWrap:self.wrap];
    }
    
    if (!_historyItem) {
        if (_candy) {
            _historyItem = [self.history itemWithCandy:_candy];
        } else {
            _historyItem = [self.history.entries firstObject];
            _candy = [_historyItem.entries firstObject];
        }
    }

    [self addNotifyReceivers];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;

    __weak typeof(self)weakSelf = self;
    WLOperationQueue *paginationQueue = [WLOperationQueue queueNamed:@"wl_candy_pagination_queue"];
    [paginationQueue setStartQueueBlock:^{
        [weakSelf.spinner startAnimating];
    }];
    [paginationQueue setFinishQueueBlock:^{
        [weakSelf.spinner stopAnimating];
    }];

    [self setCandy:_candy direction:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastComment = nil;
    [self updateOwnerData];
    if (self.showCommentViewController) {
        [self showCommentView];
    } else {
        [self setBarsHidden:NO animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WLHintView showCandySwipeHintView];
}

- (void)showCommentView {
    [self.commentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    self.showCommentViewController = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIBezierPath *exlusionPath = [UIBezierPath bezierPathWithRect:[self.bottomView convertRect:self.commentIndicator.frame
                                                                                        toView:self.lastCommentTextView]];
    
    self.lastCommentTextView.textContainer.exclusionPaths = [self.lastComment.contributor isCurrentUser] ? @[exlusionPath] : nil;
}

- (IBAction)hideBars {
    [self setBarsHidden:YES animated:YES];
}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.topViewConstraint.constant = hidden ? -weakSelf.topView.height : .0f;
        weakSelf.bottomViewContstraint.constant = hidden ? -weakSelf.bottomView.height : .0f;
        [weakSelf.view setNeedsLayout];
    }];
}

- (void)setHistoryItem:(WLHistoryItem *)historyItem direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _historyItem = historyItem;
    if (direction == WLSwipeViewControllerDirectionForward) {
        [self setCandy:[historyItem.entries firstObject] direction:direction animated:animated];
    } else {
        [self setCandy:[historyItem.entries lastObject] direction:direction animated:animated];
    }
}

- (void)setCandy:(WLCandy *)candy direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _candy = candy;
    [self setViewController:[self candyViewController:candy] direction:direction animated:animated];
}

- (void)fetchCandiesOlderThen:(WLCandy*)candy {
    WLHistoryItem *historyItem = self.historyItem;
    if (historyItem.completed || historyItem.request.loading || !candy) return;
    NSUInteger count = [historyItem.entries count];
    NSUInteger index = [historyItem.entries indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        runUnaryQueuedOperation(@"wl_candy_pagination_queue", ^(WLOperation *operation) {
            [historyItem older:^(NSOrderedSet *candies) {
                [operation finish];
            } failure:^(NSError *error) {
                if (error.isNetworkError) {
                    historyItem.completed = YES;
                }
                [operation finish];
            }];
        });
    }
}

- (void)fetchHistoryItemsOlderThen:(WLHistoryItem*)historyItem {
    WLHistory *history = self.history;
    if (history.completed || history.request.loading || !historyItem) return;
    NSUInteger count = [history.entries count];
    NSUInteger index = [history.entries indexOfObject:historyItem];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        runUnaryQueuedOperation(@"wl_candy_pagination_queue", ^(WLOperation *operation) {
            [history older:^(NSOrderedSet *candies) {
                [operation finish];
            } failure:^(NSError *error) {
                if (error.isNetworkError) {
                    historyItem.completed = YES;
                }
                [operation finish];
            }];
        });
    }
}

- (void)setCandy:(WLCandy *)candy {
    if (candy != _candy) {
        _candy = candy.valid ? candy : nil;
        if (self.isViewLoaded) [self updateOwnerData];
    }
}

- (void)setLastComment:(WLComment *)lastComment {
    if (lastComment != _lastComment) {
        _lastComment = lastComment;
        UITextView *textView = self.lastCommentTextView;
        self.avatarImageView.hidden = textView.hidden = self.self.commentIndicator.hidden = lastComment.text.length == 0;
        if (textView && !textView.hidden) {
            self.avatarImageView.url = lastComment.contributor.picture.small;
            [textView determineHyperLink:lastComment.text];
            [self.commentIndicator updateStatusIndicator:lastComment];
        }
    }
}

- (void)updateOwnerData {
    [_candy markAsRead];
    [self.candyIndicator updateStatusIndicator:_candy];
    self.candyIndicator.hidden = NO;
    self.actionButton.iconName = _candy.deletable ? @"trash" : @"warning";
    [self setCommentButtonTitle:_candy];
    self.postLabel.text = [NSString stringWithFormat:WLLS(@"Photo by %@"), _candy.contributor.name];
    NSString *timeAgoString = [_candy.createdAt.timeAgoStringAtAMPM stringByCapitalizingFirstCharacter];
    self.timeLabel.text = timeAgoString;
    self.lastComment = [_candy latestComment];
}

- (void)setCommentButtonTitle:(WLCandy *)candy {
    NSString *title = WLLS(@"Comment");
    if (candy.commentCount == 1) {
        title = WLLS(@"1 comment");
    } else if (candy.commentCount > 1){
        title = [NSString stringWithFormat:WLLS(@"%i comments"), (int)candy.commentCount];
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - WLEntryNotifyReceiver

- (WLCandy*)candyAfterDeletingCandy:(WLCandy*)candy {
    
    if (!self.wrap.candies.nonempty) {
        return nil;
    }
    
    candy = [self.historyItem.entries tryObjectAtIndex:self.currentCandyIndex];
    if (candy) {
        return candy;
    }
    
    WLHistoryItem *nextItem = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:self.historyItem] + 1];
    if (nextItem) {
        self.historyItem = nextItem;
        return [nextItem.entries firstObject];
    }
    
    candy = [self.historyItem.entries tryObjectAtIndex:self.currentCandyIndex - 1];
    if (candy) {
        return candy;
    }
    
    return [self.historyItem.entries firstObject];
}

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        
        [receiver setAddedBlock:^(WLCandy *candy) {
            weakSelf.currentCandyIndex = [weakSelf.historyItem.entries indexOfObject:weakSelf.candy];
        }];
        
        [receiver setUpdatedBlock:^(WLCandy *candy) {
            if (candy == weakSelf.candy) {
                [weakSelf updateOwnerData];
            }
        }];
        
        [receiver setDeletedBlock:^(WLCandy *candy) {
            if (candy == weakSelf.candy) {
                [WLToast showWithMessage:WLLS(@"This candy is no longer avaliable.")];
                WLCandy *nextCandy = [weakSelf candyAfterDeletingCandy:candy];
                if (nextCandy) {
                    [weakSelf setCandy:nextCandy direction:0 animated:NO];
                } else {
                    [weakSelf.navigationController popViewControllerAnimated:NO];
                }
            }
        }];
    }];
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        [receiver setDeletedBlock:^(WLWrap *wrap) {
            [WLToast showWithMessage:[NSString stringWithFormat:WLLS(@"Wrap %@ is no longer available."), [wrap name]]];
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
        }];
    }];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    WLCandy* candy = self.candy;
    if (candy.valid) {
        BOOL animate = self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
        [self.navigationController popViewControllerAnimated:animate];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (IBAction)downloadCandy:(id)sender {
    [self.candy download:^{
    } failure:^(NSError *error) {
        [error show];
    }];
    [WLToast showPhotoDownloadingMessage];
}

- (IBAction)navigationButtonClick:(WLIconButton *)sender {
    sender.userInteractionEnabled = NO;
    if (self.candy.deletable) {
        [self.candy remove:^(id object) {
            [WLToast showWithMessage:WLLS(@"Candy was deleted successfully.")];
            sender.userInteractionEnabled = YES;
        } failure:^(NSError *error) {
            [error show];
            sender.userInteractionEnabled = YES;
        }];
    } else {
        [MFMailComposeViewController messageWithCandy:self.candy];
    }
}

#pragma mark - WLSwipeViewController Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.cachedCandyViewControllers removeAllObjects];
}

- (WLCandyViewController *)candyViewController:(WLCandy*)candy {
    if (!self.cachedCandyViewControllers) {
        self.cachedCandyViewControllers = [NSMapTable weakToStrongObjectsMapTable];
        
    }
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (!candyViewController) {
        candyViewController = [WLCandyViewController instantiate:self.storyboard];
        candyViewController.candy = candy;
        [self.cachedCandyViewControllers setObject:candyViewController forKey:candy];
    }
    return candyViewController;
}

- (UIViewController *)viewControllerAfterViewController:(WLCandyViewController *)viewController {
    WLCandy *candy = viewController.candy;
    WLHistoryItem *item = self.historyItem;
    candy = [item.entries tryObjectAtIndex:[item.entries indexOfObject:candy] + 1];
    if (candy) {
        WLCandyViewController *candyViewController = [self candyViewController:candy];
        return candyViewController;
    }
    
    if (item.completed) {
        item = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:item] + 1];
        if (item) {
            self.historyItem = item;
            WLCandyViewController *candyViewController = [self candyViewController:[item.entries firstObject]];
            return candyViewController;
        }
        [self fetchHistoryItemsOlderThen:self.historyItem];
    } else {
        [self fetchCandiesOlderThen:self.candy];
    }
    
    return nil;
}

- (UIViewController *)viewControllerBeforeViewController:(WLCandyViewController *)viewController {
    WLCandy *candy = viewController.candy;
    WLHistoryItem *item = self.historyItem;
    candy = [item.entries tryObjectAtIndex:[item.entries indexOfObject:candy] - 1];
    if (candy) {
        WLCandyViewController *candyViewController = [self candyViewController:candy];
        return candyViewController;
    } else {
        item = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:item] - 1];
        if (item) {
            self.historyItem = item;
            WLCandyViewController *candyViewController = [self candyViewController:[item.entries lastObject]];
            return candyViewController;
        }
    }
    return nil;
}

- (void)didChangeViewController:(WLCandyViewController *)viewController {
    self.candy = [viewController candy];
    self.currentCandyIndex = [self.historyItem.entries indexOfObject:self.candy];
    [self fetchCandiesOlderThen:self.candy];
    [self fetchHistoryItemsOlderThen:self.historyItem];
}

- (void)didChangeOffsetForViewController:(UIViewController *)viewController offset:(CGFloat)offset {
    viewController.view.alpha = offset;
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
