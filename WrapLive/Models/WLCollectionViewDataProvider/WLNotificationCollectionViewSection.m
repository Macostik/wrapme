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

@implementation WLNotificationCollectionViewSection

- (CGSize)size:(NSIndexPath*)indexPath {
    WLComment *comment = [self.entries.entries objectAtIndex:indexPath.item];
    CGFloat textHeight = [comment.text heightWithFont:[UIFont fontWithName:WLFontOpenSansLight preset:WLFontPresetSmaller] width:[UIScreen mainScreen].bounds.size.width - WLNotificationCommentHorizontalSpacing cachingKey:"notificationCommentHeight"];
    return CGSizeMake(self.collectionView.bounds.size.width, textHeight + WLNotificationCommentVerticalSpacing);
}

@end
