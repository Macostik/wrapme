//
//  WLSet.h
//  Moji
//
//  Created by Sergey Maximenko on 8/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCollection.h"

@class WLSet;

@protocol WLSetDelegate <NSObject>

- (void)setDidChange:(WLSet*)set;

@end

@interface WLSet : NSObject <WLBaseOrderedCollection>

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic, strong) NSComparator sortComparator;

@property (nonatomic) BOOL sortDescending;

@property (nonatomic, weak) id <WLSetDelegate> delegate;

- (void)resetEntries:(NSSet*)entries;

- (BOOL)addEntries:(NSSet *)entries;

- (BOOL)addEntry:(id)entry;

- (void)removeEntry:(id)entry;

- (void)sort;

- (void)sort:(id)entry;

- (void)didChange;

@end
