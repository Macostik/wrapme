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
#import "WLWrapBroadcaster.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "WLToast.h"
#import "WLEntryManager.h"
#import "WLMenu.h"

@interface WLCommentCell () <WLMenuDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLCommentCell

+ (UIFont *)commentFont {
	static UIFont* commentFont = nil;
	if (!commentFont) {
		commentFont = [UIFont lightFontOfSize:15];
	}
	return commentFont;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.commentLabel.font = [WLCommentCell commentFont];
	self.authorImageView.layer.cornerRadius = self.authorImageView.height/2.0f;
    self.menu = [WLMenu menuWithView:self delegate:self];
}

- (void)setupItemData:(WLComment *)entry {
    [WLMenu hide];
	self.userInteractionEnabled = YES;
	self.authorNameLabel.text = [NSString stringWithFormat:@"%@, %@", entry.contributor.name, entry.createdAt.timeAgoString];
	self.commentLabel.text = entry.text;
	[self.commentLabel sizeToFitHeight];
	self.authorImageView.url = entry.contributor.picture.medium;
	self.menu.vibrate = [entry.contributor isCurrentUser];
}

#pragma mark - WLMenuDelegate

- (void)remove {
	__weak typeof(self)weakSelf = self;
	weakSelf.userInteractionEnabled = NO;
	[weakSelf.item remove:^(id object) {
		weakSelf.userInteractionEnabled = YES;
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (BOOL)menuShouldBePresented:(WLMenu *)menu {
    WLComment* comment = self.item;
	if ([comment.contributor isCurrentUser]) {
		return YES;
	} else {
		[WLToast showWithMessage:@"Cannot delete comment not posted by you."];
        return NO;
	}
}

- (NSString *)menu:(WLMenu *)menu titleForItem:(NSUInteger)item {
    return @"Delete";
}

- (SEL)menu:(WLMenu *)menu actionForItem:(NSUInteger)item {
    return @selector(remove);
}

@end
