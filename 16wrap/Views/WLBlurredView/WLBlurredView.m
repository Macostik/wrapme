//
//  WLBlurredView.m
//  moji
//
//  Created by Ravenpod on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBlurredView.h"

@implementation WLBlurredView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    UIView *view = view = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    view.backgroundColor = [UIColor clearColor];
    view.tintColor = [UIColor whiteColor];
    [view setFullFlexible];
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.frame = self.bounds;
    [self insertSubview:view atIndex:0];
}

@end
