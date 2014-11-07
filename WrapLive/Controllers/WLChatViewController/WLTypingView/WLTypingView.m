//
//  WLTypingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTypingView.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"
#import "NSArray+Additions.h"
#import "NSOrderedSet+Additions.h"

static CGFloat WLPadding = 20.0f;
static CGFloat WLMinBubbleWidth = 15.0f;
static CGFloat WLMaxTextViewWidth;

@interface WLTypingView ()

@property (weak, nonatomic) IBOutlet UILabel *nameTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;

@end

@implementation WLTypingView

- (void)setUsers:(NSMutableOrderedSet *)users {
    if (users.nonempty) {
        self.nameTextField.text = [self namesOfUsers:users];
        self.nameTextField.hidden = NO;
    } else {
        self.nameTextField.text = nil;
        self.nameTextField.hidden = YES;
    }
//    __weak __typeof(self)weakSelf = self;
//    WLMaxTextViewWidth = self.width - WLPadding;
//    [UIView performWithoutAnimation:^{
//        CGSize size = [weakSelf.nameTextField sizeThatFits:CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX)];
//        weakSelf.textViewConstraint.constant =  [UIScreen mainScreen].bounds.size.width - WLPadding - MAX(WLMinBubbleWidth, size.width);
//        [weakSelf.nameTextField layoutIfNeeded];
//    }];
}

- (NSString *)namesOfUsers:(NSMutableOrderedSet*)users {
    NSString* names = nil;
    if (users.count == 1) {
        names = [(WLUser*)[users lastObject] name];
    } else if (users.count == 2) {
        names = [NSString stringWithFormat:@"%@ and %@", [(WLUser*)users[0] name], [(WLUser*)users[1] name]];
    } else {
        WLUser* lastUser = [users lastObject];
        names = [[[[users array] arrayByRemovingObject:lastUser] valueForKey:@"name"] componentsJoinedByString:@", "];
        names = [names stringByAppendingFormat:@" and %@", lastUser.name];
    }
    return [names stringByAppendingString:@" is typing..."];
}

@end
