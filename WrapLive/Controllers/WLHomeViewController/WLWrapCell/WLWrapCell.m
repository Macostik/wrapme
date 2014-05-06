//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "WLUser.h"
#import "UIActionSheet+Blocks.h"

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
	UILongPressGestureRecognizer* removeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(remove:)];
	[self addGestureRecognizer:removeGestureRecognizer];
}

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
	self.coverView.imageUrl = wrap.picture.small;
	self.contributorsLabel.text = wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
}

- (void)prepareForReuse {
	[super prepareForReuse];
	self.coverView.image = nil;
}

+ (CGFloat)heightForItem:(id)item {
	return 66;
}

- (void)remove:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		__weak typeof(self)weakSelf = self;
		WLWrap* wrap = weakSelf.item;
		if ([wrap.contributor isCurrentUser]) {
			[UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" buttons:nil completion:^(NSUInteger index) {
				[UIActionSheet showWithTitle:@"Are you sure you want to delete this wrap?" cancel:@"No" destructive:@"Yes" buttons:nil completion:^(NSUInteger index) {
					weakSelf.userInteractionEnabled = NO;
					[[WLAPIManager instance] removeWrap:wrap success:^(id object) {
						weakSelf.userInteractionEnabled = YES;
					} failure:^(NSError *error) {
						[error show];
						weakSelf.userInteractionEnabled = YES;
					}];
				}];
			}];
		}
	}
}

@end