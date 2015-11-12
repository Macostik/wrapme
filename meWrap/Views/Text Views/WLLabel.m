//
//  WLLabel.m
//  meWrap
//
//  Created by Ravenpod on 11/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLabel.h"
#import "WLFontPresetter.h"

@implementation WLLabel

- (void)setLocalize:(BOOL)localize {
    _localize = localize;
    if (localize) {
        NSString *text = self.text;
        if (text.nonempty) {
            [super setText:text.ls];
        }
    }
}

- (void)setText:(NSString *)text {
    if (self.localize) {
        [super setText:text.ls];
    } else {
        [super setText:text];
    }
}

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.font = [self.font fontWithPreset:preset];
    [[WLFontPresetter defaultPresetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.font = [self.font fontWithPreset:self.preset];
}

@end
