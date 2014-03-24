//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLWrapEntry.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation WLWrapCell

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
	WLWrapEntry* entry = [wrap.entries lastObject];
	[self.coverView setImageWithURL:[NSURL URLWithString:entry.cover]];
}

@end
