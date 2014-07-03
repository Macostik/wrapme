//
//  WLMessageGroupCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageGroupCell.h"
#import "WLGroupedSet.h"

@interface WLMessageGroupCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation WLMessageGroupCell

- (void)setGroup:(WLGroup *)group {
	_group = group;
	self.dateLabel.text = group.name;
}

@end
