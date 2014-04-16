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

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;

@end

@implementation WLWrapCell

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
	self.coverView.imageUrl = wrap.picture.small;
	__weak typeof(self)weakSelf = self;
	[wrap contributorNames:^(NSString *names) {
		weakSelf.contributorsLabel.text = names;
		weakSelf.contributorsLabel.height = MIN(34, [weakSelf.contributorsLabel sizeThatFits:CGSizeMake(weakSelf.contributorsLabel.width, CGFLOAT_MAX)].height);
	}];
}

- (void)prepareForReuse {
	[super prepareForReuse];
	self.coverView.image = nil;
}

+ (CGFloat)heightForItem:(id)item {
	return 66;
}

@end