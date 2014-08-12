//
//  WLHomeViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedViewSection.h"

@class WLWrap;
@class WLCandy;

@interface WLHomeViewSection : WLPaginatedViewSection

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSOrderedSet* candies;

@property (strong, nonatomic) void (^candySelectionBlock) (WLCandy* candy);

@end
