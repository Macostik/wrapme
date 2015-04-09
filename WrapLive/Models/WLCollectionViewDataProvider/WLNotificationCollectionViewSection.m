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

@property (strong, nonatomic) NSMapTable *createdEntry;
@property (strong, nonatomic) NSMutableOrderedSet *retryIndexPathSet;
@property (assign, nonatomic) CGFloat addHeight;

@end

@implementation WLNotificationCollectionViewSection

- (id)cellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    NSString *_identifier = [entry isKindOfClass:[WLMessage class]] ? @"WLMessageNotificationCell" :
                            [entry isKindOfClass:[WLComment class]] ? @"WLCommentNotificationCell" :
                                                                      @"WLCandyNotificationCell";
    return [super cellWithIdentifier:_identifier indexPath:indexPath];
}

- (void)setup {
    [super setup];
    self.createdEntry = [NSMapTable weakToWeakObjectsMapTable];
    self.retryIndexPathSet = [NSMutableOrderedSet orderedSet];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = .0;
    textHeight = [entry isKindOfClass:[WLCandy class]] ? [WLCandyNotificationCell heightCell:entry] : [WLNotificationCell heightCell:entry];
    
    for (NSIndexPath *_indexPath in self.retryIndexPathSet) {
        if  ([_indexPath compare:indexPath] == NSOrderedSame) {
            textHeight += self.addHeight;
        }
    }
    
    return CGSizeMake(WLConstants.screenWidth, textHeight + WLNotificationCommentVerticalSpacing);
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

#pragma mark - WLNotificationCellDelegate 

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageByComposeBar:(WLComposeBar *)composeBar {
    NSIndexPath *indexPath =  [self.collectionView indexPathForCell:cell];
    NSIndexPath *existingIndexPath = [self openedIndexPath:indexPath];
    if (existingIndexPath) {
        [self.retryIndexPathSet removeObject:existingIndexPath];
    } else {
        [self.retryIndexPathSet addObject:indexPath];
    }
    self.addHeight = composeBar.height;
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell didChangeHeightComposeBar:(WLComposeBar *)composeBar {
    if (composeBar.height > 41) {
        self.addHeight = composeBar.height;
    }
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell calculateHeightTextView:(CGFloat)height {
    self.addHeight = MAX(height, 40);
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell createEntry:(id)entry {
    [self.createdEntry setObject:entry forKey:cell.entry];
}

- (id)notificationCell:(WLNotificationCell *)cell createdEntry:(id)entry {
    return [self.createdEntry objectForKey:entry];
}

- (NSIndexPath*)openedIndexPath:(NSIndexPath*)indexPath {
    for (NSIndexPath* _indexPath in self.retryIndexPathSet) {
        if ([_indexPath compare:indexPath] == NSOrderedSame) {
            return _indexPath;
        }
    }
    return nil;
}

@end
