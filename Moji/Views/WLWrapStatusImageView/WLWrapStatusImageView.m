//
//  WLWrapStatusImageView.m
//  Moji
//
//  Created by Sergey Maximenko on 8/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapStatusImageView.h"
#import "UIView+QuartzCoreHelper.h"

@implementation WLWrapStatusImageView

- (void)setIsFollowed:(BOOL)isFollowed {
    _isFollowed = isFollowed;
    self.statusView.hidden = !isFollowed;
    self.borderWidth = isFollowed ? 2 : 0;
    self.borderColor = isFollowed ? WLColors.dangerRed : nil;
}

- (void)setIsOwner:(BOOL)isOwner {
    _isOwner = isOwner;
    self.statusView.text = isOwner ? WLWrapStatusOwnerImage : WLWrapStatusFollowerImage;
}

@end
