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

static CGFloat WLMinBubbleWidth = 15.0f;
static CGFloat WLMaxTextViewWidth = 287.0f;

@implementation WLTypingView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.groupUsers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)setText:(NSString *)name {
    if (!name.nonempty) {
        self.hidden = YES;
        return;
    } else {
        self.hidden = NO;
    }
    self.nameTextField.text = name;
    __weak __typeof(self)weakSelf = self;
    [UIView performWithoutAnimation:^{
        CGSize size = [weakSelf.nameTextField sizeThatFits:CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX)];
        weakSelf.textViewConstraint.constant =  weakSelf.width - 20 - MAX(WLMinBubbleWidth, size.width);
        [weakSelf.nameTextField layoutIfNeeded];
    }];
}

- (void)addUser:(WLUser *)user {
    [self.groupUsers addObject:user];
    [self setText:[self componentsUserName]];
}

- (void)removeUser:(WLUser *)user {
    if ([self.groupUsers containsObject:user]) {
        [self.groupUsers removeObject:user];
    }
    if ([self hasUsers]) {
         [self setText:[self componentsUserName]];
    }
}

- (NSString *)componentsUserName {
    NSArray *users = [self.groupUsers array];
    NSMutableString *string = users.count > 1 ? [[[users valueForKey:@"name"] componentsJoinedByString:@" and "] mutableCopy] :
                                                [[users.lastObject valueForKey:@"name"] mutableCopy];
    [string appendString:@" is typing ..."];
    return string;
}

- (BOOL)hasUsers {
    return [self.groupUsers array].nonempty;
}


@end
