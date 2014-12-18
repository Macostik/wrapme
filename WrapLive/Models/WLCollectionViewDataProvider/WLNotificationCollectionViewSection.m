//
//  WLNotificationCollectionViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCollectionViewSection.h"
#import "UIFont+CustomFonts.h"
#import "WLCommentCell.h"
#import "NSString+Additions.h"
#import "WLFontPresetter.h"
#import "WLCollectionViewDataProvider.h"

@interface WLNotificationCollectionViewSection () <WLFontPresetterReceiver>

@end

@implementation WLNotificationCollectionViewSection

- (void)setup {
    [super setup];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    WLComment *comment = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = [comment.text heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller] width:[UIScreen mainScreen].bounds.size.width - WLNotificationCommentHorizontalSpacing];
    return CGSizeMake(self.collectionView.bounds.size.width, textHeight + WLNotificationCommentVerticalSpacing);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

@end
