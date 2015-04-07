//
//  WLNotificationCollectionViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCollectionViewSection.h"
#import "UIFont+CustomFonts.h"
#import "WLFontPresetter.h"
#import "WLCollectionViewDataProvider.h"
#import "WLNotificationCell.h"
#import "WLComposeBar.h"

@interface WLNotificationCollectionViewSection () <WLFontPresetterReceiver>
@property (strong, nonatomic) NSMutableOrderedSet *retryIndexPathSet;
@property (strong, nonatomic) NSIndexPath *entryIndexPath;
@property (strong, nonatomic) WLComposeBar *composeBar;
@end

@implementation WLNotificationCollectionViewSection

- (id)cellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    NSString *_identifier = [entry isKindOfClass:[WLMessage class]]? @"WLMessageNotificationCell" : @"WLCandyNotificationCell";
    return [super cellWithIdentifier:_identifier indexPath:indexPath];
}

- (void)setup {
    [super setup];
    self.retryIndexPathSet = [NSMutableOrderedSet orderedSet];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = .0;
    if ([entry respondsToSelector:@selector(text)]) {
       textHeight = [[entry text] heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular
                                                            preset:WLFontPresetNormal]
                               width:WLConstants.screenWidth - WLNotificationCommentHorizontalSpacing];
        if ([self.retryIndexPathSet containsObject:indexPath]) {
            textHeight += self.composeBar.height;
        }
    } else {
        textHeight = 22.0;
    }
    
    return CGSizeMake(WLConstants.screenWidth, textHeight + WLNotificationCommentVerticalSpacing);
}

- (BOOL)validIndexPath {
    return self.entryIndexPath.item != NSNotFound;
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

#pragma mark - WLNotificationCellDelegate 

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageThroughComposeBar:(WLComposeBar *)composeBar {
    self.entryIndexPath = [self.collectionView indexPathForCell:cell];
    if ([self validIndexPath]) {
        if (composeBar.hidden) {
            [self.retryIndexPathSet removeObject:self.entryIndexPath];
        } else {
            [self.retryIndexPathSet addObject:self.entryIndexPath];
        }
        self.composeBar = composeBar;
        [self.collectionView performBatchUpdates:nil completion:nil];
    }
}

#pragma mark - WLComposeBar

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    self.composeBar = composeBar;
    [self.collectionView performBatchUpdates:nil completion:nil];
    
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
     id entry = [self.entries.entries objectAtIndex:self.entryIndexPath.item];
    [entry setUnread:NO];
}


@end
