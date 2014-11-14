//
//  WLCollectionView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionView.h"
#import "WLLoadingView.h"

@implementation WLCollectionView

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
}

@end
