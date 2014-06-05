//
//  WLQuickChatView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLQuickChatView.h"
#import "WLComposeBar.h"
#import "UIView+Shorthand.h"
#import "WLUserView.h"
#import "WLUploadingQueue.h"
#import "NSObject+NibAdditions.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "UILabel+Additions.h"
#import "WLSupportFunctions.h"

@interface WLQuickChatView () <WLComposeBarDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet WLUserView *contributorView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) UIView *headerView;

@end

@implementation WLQuickChatView

+ (instancetype)quickChatView:(UITableView *)tableView {
    WLQuickChatView* quickChatView = [WLQuickChatView loadFromNib];
    quickChatView.tableView = tableView;
    return quickChatView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.composeBar performSelector:@selector(setPlaceholder:) withObject:@"Write your message..." afterDelay:0.0f];
}

- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    [tableView addSubview:self];
}

- (UIView *)headerView {
    UIView* headerView = self.tableView.tableHeaderView;
    if (!headerView) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
        button.userInteractionEnabled = NO;
        button.backgroundColor = [UIColor clearColor];
        button.frame = self.bounds;
        headerView = button;
        self.headerView = headerView;
    }
    return headerView;
}

- (void)setHeaderView:(UIView *)headerView {
    self.tableView.tableHeaderView = headerView;
}

- (void)setHeight:(CGFloat)height {
    [super setHeight:height];
    UIView* headerView = self.headerView;
    headerView.height = height;
    self.headerView = headerView;
}

- (void)setWrap:(WLWrap *)wrap {
    BOOL changed = ![_wrap isEqualToEntry:wrap];
    _wrap = wrap;
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        return [[wrap messages:1] lastObject];
    }, ^(WLCandy* message) {
        if (message) {
            weakSelf.contributorView.hidden = NO;
            weakSelf.contributorView.user = message.contributor;
            weakSelf.messageLabel.text = message.chatMessage;
        } else {
            weakSelf.contributorView.hidden = YES;
        }
        [weakSelf updateHeight];
        if (changed) {
            [weakSelf setOffset:weakSelf.height animated:NO];
        }
    });
}

- (void)updateHeight {
    CATransform3D t = self.layer.transform;
    self.layer.transform = CATransform3DIdentity;
    if (!self.contributorView.hidden) {
        self.height = self.contributorView.height + self.composeBar.height;
        self.composeBar.y = self.contributorView.height;
    } else {
        self.height = self.composeBar.height;
        self.composeBar.y = 0;
    }
    self.layer.transform = t;
}

- (void)setOffset:(CGFloat)offset animated:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0, offset) animated:animated];
}

#pragma mark - UITableViewDelegate

- (void)onScroll {
    CGFloat offset = self.tableView.contentOffset.y;
    if (offset > 0) {
        self.transform = CGAffineTransformMakeTranslation(0, offset);
        [self.tableView sendSubviewToBack:self];
        self.headerView.userInteractionEnabled = YES;
    } else {
        self.transform = CGAffineTransformIdentity;
        [self.tableView bringSubviewToFront:self];
        self.headerView.userInteractionEnabled = NO;
    }
}

- (void)onEndScrolling {
    CGFloat offset = self.tableView.contentOffset.y;
    CGFloat height = self.height;
    if (IsInBounds(0, height/2.0f, offset)) {
        [self show];
    } else if (IsInBounds(height/2.0f, height, offset)) {
        [self setOffset:height animated:YES];
        [self.composeBar resignFirstResponder];
    }
}

- (void)show {
    [self setOffset:0 animated:YES];
    [self.composeBar becomeFirstResponder];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.wrap success:^(id object) {
	} failure:^(NSError *error) {
	}];
}

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
    [self updateHeight];
    [self.tableView reloadData];
}

@end

@implementation UITableView (WLQuickChatView)

- (void)reloadDataAndFixBottomInset:(WLQuickChatView*)quickChatView {
    CGPoint offset = self.contentOffset;
    UIEdgeInsets insets = self.contentInset;
    insets.bottom = 0;
    self.contentInset = insets;
    [self reloadData];
    CGFloat dy = (self.height + quickChatView.height) - self.contentSize.height;
    if (dy > 0) {
        UIEdgeInsets insets = self.contentInset;
        insets.bottom = dy;
        self.contentInset = insets;
    }
    self.contentOffset = offset;
}

@end
