//
//  WLCommentCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCommentCell.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "NSDate+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLEntryNotifier.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "WLToast.h"
#import "WLEntryManager.h"
#import "WLMenu.h"
#import "NSString+Additions.h"
#import "WLCircleProgressBar.h"
#import "WLInternetConnectionBroadcaster.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"

@interface WLCommentCell ()

@property (weak, nonatomic) IBOutlet WLImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet WLCircleProgressBar *circleProgressBar;
@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLCommentCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.authorImageView.layer.cornerRadius = self.authorImageView.height/2.0f;
    __weak typeof(self)weakSelf = self;
    self.menu = [WLMenu menuWithView:self configuration:^BOOL(WLMenu *menu) {
        WLComment* comment = weakSelf.entry;
        if ([comment.contributor isCurrentUser]) {
            [menu addItemWithImage:[UIImage imageNamed:@"btn_menu_delete"] block:^{
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.entry remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
            return YES;
        } else {
            [WLToast showWithMessage:@"Cannot delete comment not posted by you."];
            return NO;
        }
    }];
    self.commentTextView.textContainerInset = UIEdgeInsetsMake(0, -5, 0, 0);
}

- (void)setup:(WLComment *)entry {
	self.userInteractionEnabled = YES;
    if (!NSNumberEqual(entry.unread, @NO)) entry.unread = @NO;
	self.authorNameLabel.text = [NSString stringWithFormat:@"%@, %@", WLString(entry.contributor.name), WLString(entry.createdAt.timeAgoString)];
    [self.commentTextView determineHyperLink:entry.text];
    __weak typeof(self)weakSelf = self;
	self.authorImageView.url = entry.contributor.picture.small;
    [self.authorImageView setFailure:^(NSError* error) {
        weakSelf.authorImageView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }];
    self.menu.vibrate = [entry.contributor isCurrentUser];
   
    if (![WLInternetConnectionBroadcaster broadcaster].reachable && !entry.uploaded) {
        self.circleProgressBar.waitUpload = YES;
    } else {
        if (entry.candy.uploading.operation) {
            self.circleProgressBar.waitUpload = YES;
        } else {
            self.circleProgressBar.operation = entry.uploading.operation;
        }
    }
}

@end
