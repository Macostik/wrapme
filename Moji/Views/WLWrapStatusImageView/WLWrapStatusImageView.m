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

- (void)setFollowed:(BOOL)followed {
    _followed = followed;
    self.statusView.hidden = !followed;
    self.borderWidth = followed ? 2 : 0;
    self.borderColor = followed ? [UIColor WL_dangerRed] : nil;
}

@end
