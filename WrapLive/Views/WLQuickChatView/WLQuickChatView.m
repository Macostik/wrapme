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
#import "NSObject+NibAdditions.h"
#import "WLEntryManager.h"
#import "UILabel+Additions.h"
#import "WLSupportFunctions.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigation.h"
#import "WLWrapViewController.h"
#import "WLChatViewController.h"
#import "NSString+Additions.h"
#import "WLAPIManager.h"

@interface WLQuickChatView () <WLComposeBarDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet WLUserView *contributorView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView* headerView;

@end

@implementation WLQuickChatView
{
    BOOL refresh;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (self.headerView == nil) {
        UIView* headerView = [UIView loadFromNibNamed:@"WLQuickChatView" ownedBy:self];
        [self addSubview:headerView];
        self.headerView = headerView;
    }
    [self.composeBar performSelector:@selector(setPlaceholder:) withObject:@"Write your message..." afterDelay:0.0f];
	__weak __typeof(self)weakSelf = self;
	self.composeBar.segmentSelectedBlock = ^(__unused NSInteger index) {
		[weakSelf delayEndEditing];
	};
    self.headerView.y = -self.headerView.height;
}

- (void)setWrap:(WLWrap *)wrap {
    BOOL changed = ![_wrap isEqualToEntry:wrap];
    _wrap = wrap;
    __weak typeof(self)weakSelf = self;
    WLCandyBlock setup = ^ (WLCandy* message) {
        weakSelf.contributorView.hidden = (message == nil);
        if (message) {
            weakSelf.contributorView.user = message.contributor;
            weakSelf.messageLabel.text = message.message;
        }
        [weakSelf updateHeight];
    };
    WLCandy* message = [[wrap messages:1] lastObject];
    if (message) {
        setup(message);
    } else if (changed) {
        [wrap latestMessage:setup failure:^(NSError *error) {
            setup(nil);
        }];
        setup(nil);
    }
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
    self.headerView.y = self.scrollView.y - self.headerView.height;
}

- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    _editing = editing;
    self.scrollView.userInteractionEnabled = !editing;
    CGFloat height = editing ? self.height - self.headerView.height : self.height;
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.scrollView.height = height;
        weakSelf.scrollView.y = weakSelf.height - height;
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
    CGFloat offset = self.scrollView.contentOffset.y;
    CGFloat height = self.scrollView.height;
    height = Smoothstep(self.height - self.headerView.height, self.height, height + offset);
    if (height != self.scrollView.height) {
        self.scrollView.height = height;
        self.scrollView.y = self.height - height;
        self.headerView.y = self.scrollView.y - self.headerView.height;
        self.scrollView.contentOffset = CGPointZero;
    }
}

- (void)onEndDragging {
    refresh = self.scrollView.contentOffset.y < -66;
}

- (void)onEndScrolling {
    CGFloat offset = self.height - self.scrollView.height;
    CGFloat height = self.headerView.height;
    if (IsInBounds(0, height/2.0f, offset)) {
        [self setEditing:NO animated:YES];
    } else if (!refresh && self.scrollView.contentOffset.y >= 0 && IsInBounds(height/2.0f, height, offset)) {
        [self setEditing:YES animated:YES];
    } else {
        [self setEditing:NO animated:YES];
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
    [self.wrap uploadMessage:text success:^(WLCandy *candy) {
        
    } failure:^(NSError *error) {
        [error show];
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
