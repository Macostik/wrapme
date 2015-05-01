//
//  WLHomeViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSectionedDataSource.h"

@class WLWrap;

@interface WLHomeDataSource : WLBasicDataSource

@property (strong, nonatomic) WLWrap* wrap;

@end
