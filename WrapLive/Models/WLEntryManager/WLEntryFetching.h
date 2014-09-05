//
//  WLEntryFetching.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryManager.h"

@class WLEntryFetching;

@protocol WLEntryFetchingDelegate <NSObject>

- (void)fetching:(WLEntryFetching*)fetching didChangeContent:(NSMutableOrderedSet*)content;

@end

@interface WLEntryFetching : NSObject

@property (readonly, nonatomic) NSMutableOrderedSet* content;

@property (strong, nonatomic) NSFetchRequest *request;

@property (nonatomic, weak) id <WLEntryFetchingDelegate> delegate;

+ (instancetype)fetching:(NSString*)name configuration:(void (^) (NSFetchRequest* request))configure;

- (instancetype)initWithName:(NSString*)name configuration:(void (^) (NSFetchRequest* request))configure;

- (void)setup:(NSString*)name configuration:(void (^)(NSFetchRequest *))configure;

- (void)perform;

- (void)addTarget:(id)target action:(SEL)action delay:(NSTimeInterval)delay;

- (void)addTarget:(id)target action:(SEL)action;

@end
