//
//  WLMessageGroupCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageGroupCell.h"
#import "WLDate.h"
#import "NSDate+Formatting.h"

@interface WLMessageGroupCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation WLMessageGroupCell

- (void)setDate:(WLDate *)date {
	_date = date;
	self.dateLabel.text = [date.date stringWithFormat:@"MMM d, yyyy"];
}

@end
