//
//  WLIconView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIconView.h"
#import "WLIcon.h"

@implementation WLIconView

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    [self setup];
}

- (void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    [self setup];
}

- (void)setIconPreset:(NSString *)iconPreset {
    _iconPreset = iconPreset;
    [self setup];
}

- (void)setup {
    self.attributedText = WLIconCreate(_iconName, _iconPreset, _iconColor);
}

@end
