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

- (void)handleContentOffset:(CGFloat)offset withContentHeight:(CGFloat)contentHeight forAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if ([attributes.representedElementKind isEqualToString:@"unreadMessagesView"]) {
        if (self.scrollToUnreadMessages) {
            UICollectionView *cv = self.collectionView;
            UIEdgeInsets insets = cv.contentInset;
            CGFloat height = contentHeight - (cv.height - insets.bottom);
            CGPoint contentOffset = CGPointMake(0, offset - (cv.height - cv.verticalContentInsets)/2);
            if (IsInBounds(-insets.top, ((height > -insets.top) ? height : -insets.top), contentOffset.y)) {
                self.collectionView.contentOffset = contentOffset;
            }
            self.scrollToUnreadMessages = NO;
        }
    }
}   

@end
