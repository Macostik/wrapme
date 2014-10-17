//
//  WLTypingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLUser.h"

@interface WLTypingView : UIView

@property (weak, nonatomic) IBOutlet UITextView *nameTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;
@property (strong, nonatomic) NSMutableOrderedSet *groupUsers;

- (void)addUser:(WLUser *)user;
- (void)removeUser:(WLUser *)user;
- (BOOL)hasUsers;

@end
