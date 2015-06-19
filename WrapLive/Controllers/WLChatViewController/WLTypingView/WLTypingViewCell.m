//
//  WLTypingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTypingViewCell.h"

@interface WLTypingViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameTextField;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@end

@implementation WLTypingViewCell

- (void)setChat:(WLChat *)chat {
    self.nameTextField.text = chat.typingNames;
    self.nameTextField.hidden = !chat.typingNames.nonempty;
    if (chat.typingUsers.count > 1) {
        [self.avatarView setImage:[UIImage imageNamed:WLFriendsTypingImage]];
    } else {
        WLUser *user = chat.typingUsers.firstObject;
        if (user.valid) {
            self.avatarView.url = user.picture.small;
        }
    }
}

@end
