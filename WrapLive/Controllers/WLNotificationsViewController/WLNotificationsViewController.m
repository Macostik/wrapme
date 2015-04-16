//
//  WLNotificationsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationsViewController.h"
#import "WLUserView.h"
#import "WLBasicDataSource.h"
#import "WLNotificationCenter.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLNotificationCell.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"

@interface WLNotificationsViewController () <WLEntryNotifyReceiver, WLNotificationCellDelegate>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@property (strong, nonatomic) NSMapTable *createdEntry;
@property (strong, nonatomic) NSMapTable *bufferInfoCell;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.createdEntry = [NSMapTable weakToWeakObjectsMapTable];
    self.bufferInfoCell = [NSMapTable strongToStrongObjectsMapTable];
    
    [self.dataSource setCellIdentifierForItemBlock:^NSString *(id entry, NSUInteger index) {
        NSString *_identifier = [entry isKindOfClass:[WLMessage class]] ? @"WLMessageNotificationCell" :
        [entry isKindOfClass:[WLComment class]] ? @"WLCommentNotificationCell" :
        @"WLCandyNotificationCell";
        return _identifier;
    }];
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setItemSizeBlock:^CGSize(id entry, NSUInteger index) {
        
        CGFloat textHeight  = [WLNotificationCell additionalHeightCell:entry];
        
        textHeight += [[weakSelf.bufferInfoCell objectForKey:entry] floatValue];
        
        UIFont *fontNormal = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                                    preset:WLFontPresetNormal];
        UIFont *fontSmall = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                                   preset:WLFontPresetSmall];
        return CGSizeMake(WLConstants.screenWidth, textHeight + 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + 2*WLPaddingCell);

    }];
    
    [self.dataSource setSelectionBlock:^(WLEntry* entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:YES];
    }];
    
    [self.dataSource setConfigureCellForItemBlock:^(WLNotificationCell *cell, id entry) {
        [cell setBackgroundColor:[entry unread] ? [UIColor whiteColor] : [UIColor WL_grayLightest]];
    }];
 
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
    [[WLMessage notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataSource.items = [[WLUser currentUser] notifications];
}

- (void)updateNotificaton {
    if (![WLKeyboard keyboard].isShow) {
       self.dataSource.items = [[WLUser currentUser] notifications];
    }
}

- (void)removeNotificationEntry:(WLEntry *)entry {
    NSMutableOrderedSet* entries = (id)self.dataSource.items;
    if ([entries containsObject:entry]) {
        [entries removeObject:entry];
        if (![WLKeyboard keyboard].isShow) {
             [self.dataSource reload];
        }
    }
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
    [self removeNotificationEntry:comment];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self removeNotificationEntry:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self removeNotificationEntry:message];
}

- (IBAction)back:(id)sender {
    [[WLEntryManager manager].context processPendingChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)keyboardDidHide:(WLKeyboard*)keyboard {
    run_after(2.0, ^{
        self.dataSource.items = [[WLUser currentUser] notifications];
    });
}

#pragma mark - WLNotificationCellDelegate

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageByComposeBar:(WLComposeBar *)composeBar {
    if ([self.bufferInfoCell objectForKey:cell.entry] != nil) {
        [self.bufferInfoCell removeObjectForKey:cell.entry];
    } else {
        [self.bufferInfoCell setObject:[NSNumber numberWithFloat:composeBar.height] forKey:cell.entry];
    }
    [self.dataSource.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell didChangeHeightComposeBar:(WLComposeBar *)composeBar {
    if (composeBar.height > WLMinHeightCell) {
        [self.bufferInfoCell setObject:[NSNumber numberWithFloat:composeBar.height] forKey:cell.entry];
    }
    [self.dataSource.collectionView performBatchUpdates:nil completion:nil];
    NSIndexPath *indexPath =  [self.dataSource.collectionView indexPathForCell:cell];
    [self.dataSource.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:YES];
}

- ( void)notificationCell:(WLNotificationCell *)cell beginEditingComposaBar:(WLComposeBar *)composeBar {
    NSIndexPath *indexPath =  [self.dataSource.collectionView indexPathForCell:cell];
    [self.dataSource.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:YES];
}

- (void)notificationCell:(WLNotificationCell *)cell calculateHeightTextView:(CGFloat)height {
    [self.bufferInfoCell setObject:[NSNumber numberWithFloat:MAX(height, WLMinHeightCell) + WLPaddingCell] forKey:cell.entry];
    [self.dataSource.collectionView performBatchUpdates:nil completion:nil];
}

- (void)notificationCell:(WLNotificationCell *)cell createEntry:(id)entry {
    [self.createdEntry setObject:entry forKey:cell.entry];
}

- (id)notificationCell:(WLNotificationCell *)cell createdEntry:(id)entry {
    return [self.createdEntry objectForKey:entry];
}

@end
