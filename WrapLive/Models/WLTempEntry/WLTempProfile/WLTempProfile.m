//
//  WLTempProfile.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTempProfile.h"
#import "WLUser.h"

@implementation WLTempProfile

- (void)setupEntry:(WLUser *)user {
    self.name = user.name;
    self.email = user.email;
    WLPicture *picture = [WLPicture new];
    picture.large = user.picture.large;
    self.picture = picture;
}

@end
