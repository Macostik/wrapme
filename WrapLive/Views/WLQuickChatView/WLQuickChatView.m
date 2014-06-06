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
#import "UIView+AnimationHelper.h"
#import "WLNavigation.h"
#import "WLWrapViewController.h"
#import "WLChatViewController.h"
#import "NSString+Additions.h"

@interface WLQuickChatView () <WLComposeBarDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet WLUserView *contributorView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIView* headerView;

@end

@implementation WLQuickChatView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.composeBar performSelector:@selector(setPlaceholder:) withObject:@"Write your message..." afterDelay:0.0f];
    UIView* headerView = [UIView loadFromNibNamed:@"WLQuickChatView" ownedBy:self];
    headerView.y = -headerView.height;
    [self addSubview:headerView];
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
        }
    });
}

- (void)updateHeight {
    if (!self.contributorView.hidden) {
        self.headerView.height = self.contributorView.height + self.composeBar.height;
        self.composeBar.y = self.contributorView.height;
    } else {
        self.headerView.height = self.composeBar.height;
        self.composeBar.y = 0;
    }
    [self updateHeaderPosition];
    
    [self setEditing:self.editing animated:YES];
}

- (void)updateHeaderPosition {
    self.headerView.y = self.tableView.y - self.headerView.height;
}

- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    _editing = editing;
    self.tableView.userInteractionEnabled = !editing;
    CGFloat height = editing ? self.height - self.headerView.height : self.height;
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.tableView.height = height;
        weakSelf.tableView.y = weakSelf.height - height;
        [weakSelf updateHeaderPosition];
    }];
    if (editing && !self.composeBar.isFirstResponder) {
        [self.composeBar becomeFirstResponder];
    } else if (!editing && self.composeBar.isFirstResponder) {
        [self.composeBar resignFirstResponder];
    }
}

#pragma mark - Actions

- (IBAction)openChat:(id)sender {
    [self.delegate quickChatView:self didOpenChat:self.wrap];
}

#pragma mark - UITableViewDelegate

- (void)onScroll {
    CGFloat offset = self.tableView.contentOffset.y;
    CGFloat height = self.tableView.height;
    height = Smoothstep(self.height - self.headerView.height, self.height, height + offset);
    if (height != self.tableView.height) {
        self.tableView.height = height;
        self.tableView.y = self.height - height;
        self.headerView.y = self.tableView.y - self.headerView.height;
    }
}

- (void)onEndScrolling {
    CGFloat offset = self.height - self.tableView.height;
    CGFloat height = self.headerView.height;
    if (IsInBounds(0, height/2.0f, offset)) {
        [self setEditing:NO animated:YES];
    } else if (self.tableView.contentOffset.y >= 0 && IsInBounds(height/2.0f, height, offset)) {
        [self setEditing:YES animated:YES];
    }
}

#pragma mark - WLComposeBarDelegate

- (void)cancelDelayEndEditing {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onDelayedEndEditing) object:nil];
}

- (void)delayEndEditing {
    [self cancelDelayEndEditing];
    [self performSelector:@selector(onDelayedEndEditing) withObject:nil afterDelay:5.0f];
}

- (void)onDelayedEndEditing {
    if (!self.composeBar.text.nonempty) {
        [self.composeBar resignFirstResponder];
    }
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.wrap success:^(id object) {
	} failure:^(NSError *error) {
	}];
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
    [self setEditing:NO animated:YES];
    [self cancelDelayEndEditing];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
    [self delayEndEditing];
}

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
    [self updateHeight];
}

- (void)composeBarDidChangeText:(WLComposeBar *)composeBar {
    [self delayEndEditing];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.editing) {
        [self setEditing:NO animated:YES];
    }
}

@end
