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

const static CGFloat WLContributorsVerticalIndent = 30.0f;
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
    CGFloat height = [user.phones heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller] width:self.collectionView.width - WLContributorsHorizontalIndent];
    return CGSizeMake(self.collectionView.width, height + WLContributorsVerticalIndent);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.collectionView reloadData];
}

@end
