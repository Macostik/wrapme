//
//  WLEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^WLEditSessionComparator)(id originalValue, id changedValue);

@class WLEntry;
@class WLEditSession;

@protocol WLEditSessionDelegate <NSObject>

- (void)editSession:(WLEditSession*)session hasChanges:(BOOL)hasChanges;

@end

@interface WLEditSession : NSObject
{
@package
    NSMutableDictionary *_original;
    NSMutableDictionary *_changed;
    __weak WLEntry *_entry;
}

@property (nonatomic, weak) id <WLEditSessionDelegate> delegate;

@property (readonly, strong, nonatomic) NSMutableDictionary *original;

@property (readonly, strong, nonatomic) NSMutableDictionary *changed;

@property (readonly, weak, nonatomic) WLEntry* entry;

@property (readonly, nonatomic) BOOL hasChanges;

- (id)initWithEntry:(WLEntry *)entry properties:(NSSet*)properties;

- (id)initWithEntry:(WLEntry *)entry stringProperties:(NSString*)keyPath, ... NS_REQUIRES_NIL_TERMINATION;

- (void)setup:(NSMutableDictionary *)dictionary;

- (void)apply:(NSMutableDictionary *)dictionary;

- (void)apply;

- (void)reset;

- (void)clean;

- (id)valueForProperty:(NSString*)keyPath;

- (void)setValue:(id)value forProperty:(NSString*)keyPath;

- (BOOL)isPropertyChanged:(NSString*)keyPath;

@end

@interface WLEditSessionProperty : NSObject
{
@package
    __weak WLEditSession *_editSession;
}

@property (strong, nonatomic) NSString* keyPath;

@property (strong, nonatomic) WLEditSessionComparator comparator;

@property (readonly, nonatomic) BOOL changed;

+ (instancetype)stringProperty:(NSString*)keyPath;

+ (instancetype)property:(NSString*)keyPath comparator:(WLEditSessionComparator)comparator;

@end
