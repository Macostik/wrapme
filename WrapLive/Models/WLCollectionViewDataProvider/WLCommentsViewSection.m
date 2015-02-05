//
//  WLCommentsViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 29/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCommentsViewSection.h"
#import "UIFont+CustomFonts.h"
#import "WLCollectionViewDataProvider.h"

static CGFloat WLNotificationCommentHorizontalSpacing = 80.0f;
static CGFloat WLNotificationCommentVerticalSpacing = 66.0f;

@implementation WLCommentsViewSection

- (void)setup {
    [super setup];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    WLComment *comment = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = [comment.text heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular
                                                                             preset:WLFontPresetSmall]
                                                width:[UIScreen mainScreen].bounds.size.width - WLNotificationCommentHorizontalSpacing];
    return CGSizeMake(self.collectionView.bounds.size.width, textHeight + WLNotificationCommentVerticalSpacing);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

@end
