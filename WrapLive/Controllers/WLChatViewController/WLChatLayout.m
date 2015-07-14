//
//  WLChatLayout.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLChatLayout.h"
#import "UIScrollView+Additions.h"

@implementation WLChatLayout

- (void)prepareLayout {
    self.unreadMessagesViewIndexPath = nil;
    [super prepareLayout];
}

- (void)handleContentOffset:(CGFloat)offset withContentHeight:(CGFloat)contentHeight forAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if ([attributes.representedElementKind isEqualToString:@"unreadMessagesView"]) {
        self.unreadMessagesViewIndexPath = attributes.indexPath;
        if (self.scrollToUnreadMessages) {
            UICollectionView *cv = self.collectionView;
            CGFloat height = MAX(0, contentHeight - cv.height);
            CGPoint contentOffset = CGPointMake(0, Smoothstep(0, height, offset - cv.height/2));
            self.collectionView.contentOffset = contentOffset;
            self.scrollToUnreadMessages = NO;
        }
    }
}   

@end
