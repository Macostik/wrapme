//
//  WLLabel.m
//  meWrap
//
//  Created by Ravenpod on 11/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLabel.h"
#import "WLFontPresetter.h"
#import "UIFont+CustomFonts.h"

@implementation WLLabel

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.font = [self.font preferredFontWithPreset:preset];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.font = [self.font preferredFontWithPreset:self.preset];
}

@end
