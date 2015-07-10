//
//  WLUnreadMessagesView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/29/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUnreadMessagesView.h"
#import "WLChat.h"

@interface WLUnreadMessagesView ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation WLUnreadMessagesView

- (void)updateWithChat:(WLChat*)chat {
    NSUInteger numberOfUnreadMessages = MAX(0, chat.unreadMessages.count - chat.readMessages.count);
    NSString *text = nil;
    if (numberOfUnreadMessages == 1) {
        text = [NSString stringWithFormat:WLLS(@"unread_message"), (unsigned long)numberOfUnreadMessages, WLLS(@"oe_Ending"), WLLS(@"ue_Ending")];
    } else if (numberOfUnreadMessages < 5) {
        text = [NSString stringWithFormat:WLLS(@"unread_message"), (unsigned long)numberOfUnreadMessages, WLLS(@"sORix_Ending"), WLLS(@"iya_Ending")];
    } else {
        text = [NSString stringWithFormat:WLLS(@"unread_message"), (unsigned long)numberOfUnreadMessages, WLLS(@"sORix_Ending"), WLLS(@"ii_Ending")];
    }
    self.textLabel.text = text;
}

@end
