//
//  WLEditSession.h
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^WLEditSessionComparator)(id originalValue, id changedValue);

@class WLEditSession;

@interface WLEditSessionProperty : NSObject

@property (readonly, weak, nonatomic) WLEditSession* editSession;

@property (strong, nonatomic) NSString* keyPath;

@property (strong, nonatomic) WLEditSessionComparator comparator;

@property (readonly, nonatomic) BOOL changed;

@property (strong, nonatomic) id changedValue;

@property (strong, nonatomic) id originalValue;

+ (instancetype)stringProperty:(NSString*)keyPath;

+ (instancetype)property:(NSString*)keyPath comparator:(WLEditSessionComparator)comparator;

- (id)initialOriginalValue;

- (void)apply:(id)value;

- (void)apply;

- (void)reset;

- (void)clean;

@end

@protocol WLEditSessionDelegate <NSObject>

@optional
- (void)editSession:(WLEditSession*)session hasChanges:(BOOL)hasChanges;

@end

@interface WLEditSession : NSObject

@property (nonatomic, weak) id <WLEditSessionDelegate> delegate;

@property (readonly, weak, nonatomic) id entry;

@property (readonly, nonatomic) BOOL hasChanges;

@property (readonly, strong, nonatomic) NSMutableDictionary *properties;

- (id)initWithEntry:(id)entry properties:(NSSet*)properties;

- (id)initWithEntry:(id)entry stringProperties:(NSString*)keyPath, ... NS_REQUIRES_NIL_TERMINATION;

- (void)apply;

- (void)reset;

- (void)clean;

- (id)originalValueForProperty:(NSString*)keyPath;

- (id)changedValueForProperty:(NSString*)keyPath;

- (void)changeValue:(id)value forProperty:(NSString*)keyPath;

- (BOOL)isPropertyChanged:(NSString*)keyPath;

@end
