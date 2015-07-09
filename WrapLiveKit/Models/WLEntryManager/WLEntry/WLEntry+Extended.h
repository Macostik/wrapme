//
//  WLEntry.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"
#import "NSDictionary+Extended.h"
#import "WLCollections.h"
#import "NSString+Additions.h"
#import "WLEntryKeys.h"
#import "WLEntry+Containment.h"

@interface WLEntry (Extended)

+ (instancetype)entry;

+ (instancetype)entry:(NSString *)identifier containingEntry:(WLEntry*)containingEntry;

+ (NSSet*)API_entries:(NSArray*)array;

+ (instancetype)API_entry:(NSDictionary*)dictionary;

+ (NSSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry;

+ (NSSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry container:(NSMutableSet*)container;

+ (instancetype)API_entry:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry;

+ (NSString*)API_identifier:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry;

- (BOOL)isEqualToEntry:(WLEntry*)entry;

- (NSComparisonResult)compare:(WLEntry*)entry;

- (void)touch;

- (void)touch:(NSDate*)date;

- (void)editPicture:(NSString*)original large:(NSString*)large medium:(NSString*)medium small:(NSString*)small;

- (void)editPicture:(NSString*)large medium:(NSString*)medium small:(NSString*)small;

- (void)markAsRead;

- (void)markAsUnread;

@end
