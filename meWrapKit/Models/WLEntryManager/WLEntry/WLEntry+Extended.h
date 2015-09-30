//
//  WLEntry.h
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry.h"
#import "NSDictionary+Extended.h"
#import "WLCollections.h"
#import "NSString+Additions.h"
#import "WLEntryKeys.h"
#import "WLEntry+Containment.h"

@interface WLEntry (Extended)

+ (instancetype)entry;

+ (instancetype)entry:(NSString *)identifier container:(WLEntry*)container;

+ (NSSet*)API_entries:(NSArray*)array;

+ (instancetype)API_entry:(NSDictionary*)dictionary;

+ (NSSet*)API_entries:(NSArray*)array container:(id)container;

+ (instancetype)API_entry:(NSDictionary*)dictionary container:(id)container;

+ (NSString*)API_identifier:(NSDictionary*)dictionary;

+ (NSString *)API_uploadIdentifier:(NSDictionary *)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary container:(id)container;

+ (NSArray*)API_prefetchArray:(NSArray*)array;

+ (NSDictionary*)API_prefetchDictionary:(NSDictionary*)dictionary;

+ (void)API_prefetchDescriptors:(NSMutableArray*)descriptors inArray:(NSArray*)array;

+ (void)API_prefetchDescriptors:(NSMutableArray*)descriptors inDictionary:(NSDictionary*)dictionary;

- (BOOL)isEqualToEntry:(WLEntry*)entry;

- (NSComparisonResult)compare:(WLEntry*)entry;

- (void)touch;

- (void)touch:(NSDate*)date;

- (void)editPicture:(WLPicture*)editedPicture;

- (void)markAsRead;

- (void)markAsUnread;

@end
