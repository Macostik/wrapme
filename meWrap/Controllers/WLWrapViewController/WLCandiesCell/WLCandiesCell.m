//
//  WLWrapCandiesCell.m
//  meWrap
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesCell.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLHistoryItem.h"

@interface WLCandiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation WLCandiesCell

- (void)setup:(Candy*)candy {
	self.dateLabel.text = [candy.createdAt stringWithDateStyle:NSDateFormatterMediumStyle];
}

@end
