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
@property (strong, nonatomic) NSMapTable *bufferInfoCell;

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
    self.bufferInfoCell = [NSMapTable strongToStrongObjectsMapTable];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    __block CGFloat textHeight = .0;
    textHeight = [entry isKindOfClass:[WLCandy class]] ? [WLCandyNotificationCell heightCell:entry] :
                                                         [WLNotificationCell heightCell:entry];
    
    NSEnumerator *key = [self.bufferInfoCell keyEnumerator];
    id _key = nil;
    while((_key = [key nextObject]) != nil) {
        if ([_key isEqual:entry]) {
            CGFloat height = [[self.bufferInfoCell objectForKey:_key] floatValue];
            textHeight += height;
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
    WLEntry *entry = [self openedCellEntry:cell.entry];
    if (entry) {
        [self.bufferInfoCell removeObjectForKey:entry];
    } else {
        [self.bufferInfoCell setObject:[NSNumber numberWithFloat:composeBar.height] forKey:cell.entry];
    }
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell didChangeHeightComposeBar:(WLComposeBar *)composeBar {
    if (composeBar.height > WLMinHeightCell) {
        [self.bufferInfoCell setObject:[NSNumber numberWithFloat:composeBar.height] forKey:cell.entry];
    }
    [self.collectionView performBatchUpdates:nil completion:nil];
    NSIndexPath *indexPath =  [self.collectionView indexPathForCell:cell];
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:YES];
}

- ( void)notificationCell:(WLNotificationCell *)cell beginEditingComposaBar:(WLComposeBar *)composeBar {
    NSIndexPath *indexPath =  [self.collectionView indexPathForCell:cell];
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:YES];
}

- (void)notificationCell:(WLNotificationCell *)cell calculateHeightTextView:(CGFloat)height {
    [self.bufferInfoCell setObject:[NSNumber numberWithFloat:MAX(height, WLMinHeightCell)] forKey:cell.entry];
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell createEntry:(id)entry {
    [self.createdEntry setObject:entry forKey:cell.entry];
}

- (id)notificationCell:(WLNotificationCell *)cell createdEntry:(id)entry {
    return [self.createdEntry objectForKey:entry];
}

- (WLEntry *)openedCellEntry:(WLEntry *)entry {
    NSEnumerator *key = [self.bufferInfoCell keyEnumerator];
    id _key = nil;
    while((_key = [key nextObject]) != nil) {
        if ([_key isEqual:entry]) {
            return entry;
        }
    }
    return nil;
}

@end
