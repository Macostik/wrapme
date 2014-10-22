//
//  WLEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"
#import "NSDictionary+Extended.h"
#import "WLEntry.h"

@interface WLEditSessionProperty ()

@property (weak, nonatomic) WLEditSession* editSession;

@end

@implementation WLEditSessionProperty

+ (instancetype)stringProperty:(NSString *)keyPath {
    return [self property:keyPath comparator:^BOOL(id originalValue, id changedValue) {
        return [originalValue isEqualToString:changedValue];
    }];
}

+ (instancetype)property:(NSString *)keyPath comparator:(WLEditSessionComparator)comparator {
    WLEditSessionProperty* property = [[self alloc] init];
    property.keyPath = keyPath;
    property.comparator = comparator;
    return property;
}

- (void)setEditSession:(WLEditSession *)editSession {
    _editSession = editSession;
    self.originalValue = [self initialOriginalValue];
    self.changedValue = self.originalValue;
}

- (BOOL)changed {
    return !self.comparator(self.originalValue,self.changedValue);
}

- (id)initialOriginalValue {
    return [self.editSession.entry valueForKeyPath:self.keyPath];
}

- (void)apply:(id)value {
    if (value) {
        [self.editSession.entry setValue:value forKeyPath:self.keyPath];
    }
}

- (void)apply {
    [self apply:self.changedValue];
}

- (void)reset {
    [self apply:self.originalValue];
}

- (void)clean {
    self.changedValue = self.originalValue;
}

@end

@interface WLEditSession ()

@property (nonatomic) BOOL hasChanges;

@property (strong, nonatomic) NSMutableDictionary *properties;

@property (weak, nonatomic) WLEntry* entry;

@end

@implementation WLEditSession

- (id)initWithEntry:(WLEntry *)entry properties:(NSSet *)properties {
    self = [super init];
    if (self) {
        self.properties = [NSMutableDictionary dictionary];
        self.entry = entry;
        for (WLEditSessionProperty *property in properties) {
            property.editSession = self;
            [_properties setObject:property forKey:property.keyPath];
        }
    }
    return self;
}

- (id)initWithEntry:(WLEntry *)entry stringProperties:(NSString *)keyPath, ... {
    NSMutableSet *properties = [NSMutableSet set];
    va_list args;
    va_start(args, keyPath);
    
    for (; keyPath != nil; keyPath = va_arg(args, id)) {
        [properties addObject:[WLEditSessionProperty stringProperty:keyPath]];
    }
    va_end(args);
    return [self initWithEntry:entry properties:[properties copy]];
}

- (void)apply {
    for (WLEditSessionProperty *property in [self.properties allValues]) {
        [property apply];
    }
}

- (void)reset {
    for (WLEditSessionProperty *property in [self.properties allValues]) {
        [property reset];
    }
}

- (void)clean {
    for (WLEditSessionProperty *property in [self.properties allValues]) {
        [property clean];
    }
    self.hasChanges = NO;
}

- (void)setHasChanges:(BOOL)hasChanges {
    if (_hasChanges != hasChanges) {
        _hasChanges = hasChanges;
        [self.delegate editSession:self hasChanges:hasChanges];
    }
}

- (id)originalValueForProperty:(NSString *)keyPath {
    WLEditSessionProperty *property = [self.properties objectForKey:keyPath];
    return property.originalValue;
}

- (id)changedValueForProperty:(NSString *)keyPath {
    WLEditSessionProperty *property = [self.properties objectForKey:keyPath];
    return property.changedValue;
}

- (void)changeValue:(id)value forProperty:(NSString *)keyPath {
    WLEditSessionProperty *property = [self.properties objectForKey:keyPath];
    property.changedValue = value;
    self.hasChanges = [self updatedHasChangesValue];
}

- (void)changeValueForProperty:(NSString *)keyPath valueBlock:(id (^)(id changedValue))valueBlock {
    if (!valueBlock) return;
    WLEditSessionProperty *property = [self.properties objectForKey:keyPath];
    property.changedValue = valueBlock(property.changedValue);
    self.hasChanges = [self updatedHasChangesValue];
}

- (BOOL)isPropertyChanged:(NSString *)keyPath {
    WLEditSessionProperty *property = [self.properties objectForKey:keyPath];
    return property.changed;
}

- (BOOL)updatedHasChangesValue {
    for (WLEditSessionProperty *property in [self.properties allValues]) {
        if (property.changed) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation WLOrderedSetEditSessionProperty

+ (instancetype)property:(NSString *)keyPath {
    return [self property:keyPath comparator:^BOOL(id originalValue, id changedValue) {
        return [originalValue isEqualToOrderedSet:changedValue];
    }];
}

- (id)initialOriginalValue {
    return [NSOrderedSet orderedSet];
}

- (void)apply:(id)value {
    
}

@end
