//
//  WLMessageGroupCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageGroupCell.h"
#import "WLGroupedSet.h"
#import "NSDate+Formatting.h"
#import "WLChat.h"

@interface WLMessageGroupCell ()

@end

@implementation WLMessageGroupCell

- (void)setGroup:(WLPaginatedSet *)group {
	_group = group;
	self.dateLabel.text = [[group date] string];
}

@end
