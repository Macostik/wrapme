//
//  GridLayout.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamLayout.h"

@class GridLayout;

@protocol GridLayoutDelegate <StreamViewDelegate>

@optional

- (NSInteger)streamView:(StreamView*)streamView layoutNumberOfColumns:(GridLayout*)layout;

- (CGFloat)streamView:(StreamView*)streamView layout:(GridLayout*)layout rangeForColumn:(NSInteger)column;

- (CGFloat)streamView:(StreamView*)streamView layout:(GridLayout*)layout sizeForColumn:(NSInteger)column;

@end

@interface GridLayout : StreamLayout

@property (nonatomic) NSInteger numberOfColumns;

- (void)flatten;

@end
