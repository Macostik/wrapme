//
//  WLContributorsViewSection.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/19/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsViewSection.h"
#import "UIFont+CustomFonts.h"
#import "UIView+Shorthand.h"

const static CGFloat WLIndent = 36.0f;

@implementation WLContributorsViewSection

- (CGSize)size:(NSIndexPath *)indexPath {
    WLUser* user = self.entries.entries[indexPath.item];
    CGSize size = [user.phones sizeWithAttributes:@{NSFontAttributeName : [UIFont lightFontOfSize:13.0f]}];
    int height = size.height + WLIndent;
    return CGSizeMake(self.collectionView.width, height);
}

@end
