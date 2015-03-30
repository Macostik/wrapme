//
//  WLContributorsViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/19/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewSection.h"
#import "UIFont+CustomFonts.h"
#import "WLFontPresetter.h"

const static CGFloat WLContributorsVerticalIndent = 48.0f;
const static CGFloat WLContributorsHorizontalIndent = 96.0f;
const static CGFloat WLContributorsMinHeight = 72.0f;

@interface WLContributorsViewSection () <WLFontPresetterReceiver>

@end

@implementation WLContributorsViewSection

- (void)setup {
    [super setup];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath *)indexPath {
    WLUser* user = self.entries.entries[indexPath.item];
    CGFloat height = [user.securePhones heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller] width:self.collectionView.width - WLContributorsHorizontalIndent];
    return CGSizeMake(self.collectionView.width, MAX(height + WLContributorsVerticalIndent, WLContributorsMinHeight) + 1);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.collectionView reloadData];
}

@end
