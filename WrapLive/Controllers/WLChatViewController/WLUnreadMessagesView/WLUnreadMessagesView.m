//
//  WLUnreadMessagesView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/29/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUnreadMessagesView.h"

@interface WLUnreadMessagesView ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation WLUnreadMessagesView

- (void)setNumberOfUnreadMessages:(NSUInteger)numberOfUnreadMessages {
    self.textLabel.text = [NSString stringWithFormat:WLLS(@"unread_message"), (unsigned long)numberOfUnreadMessages, numberOfUnreadMessages > 1 ? @"S" : @""];
}

@end
