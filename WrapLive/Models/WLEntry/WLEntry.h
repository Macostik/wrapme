//
//  WLEntry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import "WLPicture.h"
#import "NSArray+Additions.h"

@interface WLEntry : WLArchivingObject

@property (strong, nonatomic) WLPicture* picture;
@property (strong, nonatomic) NSDate* createdAt;
@property (strong, nonatomic) NSDate *updatedAt;
@property (strong, nonatomic) NSString* identifier;

+ (instancetype)entry;

+ (NSDictionary*)pictureMapping;

+ (NSArray *)entriesForDate:(NSDate *)date inArray:(NSArray *)entries;

- (BOOL)isEqualToEntry:(WLEntry*)entry;

+ (EqualityBlock)equalityBlock;

@end

@interface NSArray (WLEntrySorting)

- (NSArray*)sortedEntries;

- (NSArray *)arrayByRemovingEntry:(WLEntry*)entry;

- (BOOL)containsEntry:(WLEntry*)entry;

@end

@interface NSMutableArray (WLEntrySorting)

- (void)sortEntries;

@end
