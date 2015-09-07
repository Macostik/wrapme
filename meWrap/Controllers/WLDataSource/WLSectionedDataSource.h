//
//  WLSectionedDataSource.h
//  meWrap
//
//  Created by Ravenpod on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBasicDataSource.h"

@interface WLSectionedDataSource : WLBasicDataSource

@property (nonatomic) NSUInteger numberOfDescendants;

@property (strong, nonatomic) NSUInteger (^numberOfDescendantsBlock) (id item);

@property (strong, nonatomic) id (^descendantAtIndexBlock) (NSUInteger index, id item);

@end
