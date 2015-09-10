//
//  WLTypingView.m
//  meWrap
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTypingView.h"
#import "WLLayoutPrioritizer.h"

@interface WLTypingView ()

@property (weak, nonatomic) IBOutlet UILabel *nameTextField;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *layoutPrioritizer;

@end

@implementation WLTypingView

- (void)updateWithChat:(WLChat *)chat {
    
    BOOL isHidden = !chat.typingUsers.nonempty;
    
    __weak typeof(self)weakSelf = self;
    void (^updateBlock)(void) = ^{
        NSString *typingNames = chat.typingNames;
        weakSelf.nameTextField.text = typingNames;
        weakSelf.nameTextField.hidden = !typingNames.nonempty;
        WLUser *user = chat.typingUsers.firstObject;
        if (chat.typingUsers.count == 1 && user.valid) {
            weakSelf.avatarView.url = user.picture.small;
        } else {
            weakSelf.avatarView.url = nil;
            [weakSelf.avatarView setImage:[UIImage imageNamed:WLFriendsTypingImage]];
        }
    };
    
    if (self.layoutPrioritizer.defaultState != isHidden) {
        
        if (isHidden) {
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                weakSelf.layoutPrioritizer.defaultState = isHidden;
            } completion:^(BOOL finished) {
                updateBlock();
            }];
        } else {
            updateBlock();
            [self.layoutPrioritizer setDefaultState:isHidden animated:YES];
        }
        
    } else {
        updateBlock();
    }
}

@end
