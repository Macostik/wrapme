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

@implementation WLNotificationCollectionViewSection

- (CGSize)size:(NSIndexPath*)indexPath {
    WLComment *comment = [self.entries.entries objectAtIndex:indexPath.row];
    CGSize size = [comment.text sizeWithAttributes:@{NSFontAttributeName : [UIFont lightFontOfSize:13.0f]}];
    int height = size.height * ceilf(size.width/WLCommentTextViewLenght) + WLIndent;
    return CGSizeMake(self.collectionView.bounds.size.width, height);
}

@end
