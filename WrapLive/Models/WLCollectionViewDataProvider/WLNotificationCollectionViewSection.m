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
@property (strong, nonatomic) NSIndexPath *retryIndexPath;
@property (strong, nonatomic) WLComposeBar *composeBar;
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
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    id entry = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = .0;
    textHeight = [entry isKindOfClass:[WLCandy class]] ? [WLCandyNotificationCell heightCell:entry] : [WLNotificationCell heightCell:entry];
    
    if (self.retryIndexPath != nil && [self.retryIndexPath compare:indexPath] == NSOrderedSame) {
        textHeight += self.composeBar.height;
    }
    
    return CGSizeMake(WLConstants.screenWidth, textHeight + WLNotificationCommentVerticalSpacing);
}

- (BOOL)validIndexPath {
    return self.retryIndexPath.item != NSNotFound;
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

#pragma mark - WLNotificationCellDelegate 

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageThroughComposeBar:(WLComposeBar *)composeBar {
    self.retryIndexPath = [self.collectionView indexPathForCell:cell];
    if ([self validIndexPath]) {
        self.retryIndexPath = !composeBar.hidden ? self.retryIndexPath : nil;
        self.composeBar = composeBar;
        [self.collectionView performBatchUpdates:nil completion:nil];
    }
}

#pragma mark - WLComposeBar

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    self.composeBar = composeBar;
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell createEntry:(id)entry {
    [self.createdEntry setObject:entry forKey:cell.entry];
}

- (id)notificationCell:(WLNotificationCell *)cell createdEntry:(id)entry {
    return [self.createdEntry objectForKey:entry];
}

@end
