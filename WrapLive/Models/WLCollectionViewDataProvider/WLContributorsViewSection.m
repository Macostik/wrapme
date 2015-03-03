//
//  WLContributorsViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/19/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewSection.h"
#import "UIFont+CustomFonts.h"
#import "UIView+Shorthand.h"
#import "WLFontPresetter.h"
#import "NSString+Additions.h"
#import "WLContribution+Extended.h"

const static CGFloat WLContributorsVerticalIndent = 32.0f;
const static CGFloat WLContributorsHorizontalIndent = 100.0f;

@interface WLContributorsViewSection () <WLFontPresetterReceiver>

@end

@implementation WLContributorsViewSection

- (void)setup {
    [super setup];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath *)indexPath {
    WLUser* user = self.entries.entries[indexPath.item];
    BOOL activated = [user.devices match:^BOOL(WLDevice *device) {
        return device.activated;
    }];
    CGFloat height = [user.securePhones heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller] width:self.collectionView.width - WLContributorsHorizontalIndent];
    if (self.wrap.contributedByCurrentUser && ![user isCurrentUser] && !activated) {
        return CGSizeMake(self.collectionView.width, MAX(height + WLContributorsVerticalIndent, 83));
    } else {
        return CGSizeMake(self.collectionView.width, height + WLContributorsVerticalIndent);
    }
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.collectionView reloadData];
}

@end
