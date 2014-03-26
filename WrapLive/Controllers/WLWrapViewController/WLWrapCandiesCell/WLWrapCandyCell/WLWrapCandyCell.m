//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandyCell.h"
#import "WLCandy.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLComment.h"

@interface WLWrapCandyCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation WLWrapCandyCell

- (void)setupItemData:(WLCandy*)entry {
	[self.coverView setImageWithURL:[NSURL URLWithString:entry.cover]];
	WLComment* comment = [entry.comments lastObject];
	self.commentLabel.text = comment.text;
}

@end
