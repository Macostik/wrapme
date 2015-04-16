//
//  WLEntriesCollection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPaginatedSet.h"

@protocol WLEntriesCollectionObject <NSObject>

@property (readonly, nonatomic) NSMutableOrderedSet* entries;

@end

typedef id <WLEntriesCollectionObject> WLEntriesCollection;

@interface NSMutableOrderedSet (WLEntriesCollection) <WLEntriesCollectionObject> @end

@implementation NSMutableOrderedSet (WLEntriesCollection)

- (NSMutableOrderedSet *)entries {
    return self;
}

@end

@interface WLPaginatedSet (WLEntriesCollection) <WLEntriesCollectionObject> @end

@implementation WLPaginatedSet (WLEntriesCollection) @end
