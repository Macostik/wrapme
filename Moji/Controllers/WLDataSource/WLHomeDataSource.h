//
//  WLHomeViewSection.h
//  moji
//
//  Created by Ravenpod on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "PaginatedStreamDataSource.h"
#import "WLRecentCandiesView.h"

@class WLWrap;

@interface WLHomeDataSource : PaginatedStreamDataSource

@property (strong, nonatomic) WLWrap* wrap;

@end
