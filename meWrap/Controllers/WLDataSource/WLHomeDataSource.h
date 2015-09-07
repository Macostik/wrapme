//
//  WLHomeViewSection.h
//  meWrap
//
//  Created by Ravenpod on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSectionedDataSource.h"
#import "WLRecentCandiesView.h"

@class WLWrap;

@interface WLHomeDataSource : WLBasicDataSource

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLRecentCandiesView *candiesView;

@end
