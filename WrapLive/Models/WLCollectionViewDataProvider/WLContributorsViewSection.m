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

const static CGFloat WLIndent = 36.0f;

@interface WLContributorsViewSection () <WLFontPresetterReceiver>

@end

@implementation WLContributorsViewSection

- (void)setup {
    [super setup];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath *)indexPath {
    WLUser* user = self.entries.entries[indexPath.item];
    CGSize size = [user.phones sizeWithAttributes:@{NSFontAttributeName : [UIFont fontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller]}];
    int height = size.height + WLIndent;
    return CGSizeMake(self.collectionView.width, height);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.collectionView reloadData];
}

@end
