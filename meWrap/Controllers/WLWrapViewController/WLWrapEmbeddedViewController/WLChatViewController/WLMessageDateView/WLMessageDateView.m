//
//  WLMessageDateView.m
//  meWrap
//
//  Created by Ravenpod on 2/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLMessageDateView.h"
#import "WLEntryManager.h"
#import "NSDate+Formatting.h"

@interface WLMessageDateView ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation WLMessageDateView

- (void)setMessage:(WLMessage *)message {
    _message = message;
    self.dateLabel.text = [message.createdAt stringWithDateStyle:NSDateFormatterMediumStyle];
}

@end
