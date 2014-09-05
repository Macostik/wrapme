//
//  WLEntry.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"
#import "NSDictionary+Extended.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSMutableOrderedSet+Sorting.h"
#import "WLEntryKeys.h"

@interface WLEntry (Extended)

+ (instancetype)entry;

+ (NSOrderedSet*)API_entries:(NSArray*)array;

+ (instancetype)API_entry:(NSDictionary*)dictionary;

+ (NSOrderedSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry;

+ (NSMutableOrderedSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry container:(NSMutableOrderedSet*)container;

+ (instancetype)API_entry:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry;

+ (NSString*)API_identifier:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry;

- (BOOL)isEqualToEntry:(WLEntry*)entry;

- (NSComparisonResult)compare:(WLEntry*)entry;

- (void)touch;

- (void)touch:(NSDate*)date;

- (void)editPicture:(NSString*)large medium:(NSString*)medium small:(NSString*)small;

@end
