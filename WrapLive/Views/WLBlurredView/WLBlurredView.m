//
//  WLBlurredView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBlurredView.h"
#import "UIDevice+SystemVersion.h"
#import "UIView+Shorthand.h"

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
    UIView *view = nil;
    if (SystemVersionGreaterThanOrEqualTo8()) {
        view = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    } else {
        UIToolbar* toolbar = [[UIToolbar alloc] init];
        toolbar.translucent = YES;
        view = toolbar;
    }
    view.backgroundColor = [UIColor clearColor];
    view.tintColor = [UIColor whiteColor];
    [view setFullFlexible];
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.frame = self.bounds;
    [self addSubview:view];
}

@end
