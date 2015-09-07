//
//  WLLoneDataSource.m
//  meWrap
//
//  Created by Ravenpod on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLoneDataSource.h"

@implementation WLLoneDataSource

- (NSUInteger)numberOfItems {
    return self.item ? 1 : 0;
}

- (id)itemAtIndex:(NSUInteger)index {
    return self.item;
}

@end
