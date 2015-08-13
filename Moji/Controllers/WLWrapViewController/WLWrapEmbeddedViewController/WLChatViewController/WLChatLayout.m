//
//  WLChatLayout.m
//  moji
//
//  Created by Ravenpod on 7/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLChatLayout.h"
#import "UIScrollView+Additions.h"

@implementation WLChatLayout

- (void)prepareLayout {
    self.unreadMessagesViewIndexPath = nil;
    [super prepareLayout];
}

- (void)didPrepareAttributes:(UICollectionViewLayoutAttributes *)attributes withContentHeight:(CGFloat)contentHeight {
    if ([attributes.representedElementKind isEqualToString:@"unreadMessagesView"]) {
        self.unreadMessagesViewIndexPath = attributes.indexPath;
        if (self.scrollToUnreadMessages) {
            CGFloat maxOffset = contentHeight - self.collectionView.height;
            if (maxOffset > 0) {
                CGFloat offset = attributes.frame.origin.y - self.collectionView.height/2 + attributes.frame.size.height/2;
                self.collectionView.contentOffset = CGPointMake(0, Smoothstep(0, maxOffset, offset));
            }
            self.scrollToUnreadMessages = NO;
        }
    }
}

@end
