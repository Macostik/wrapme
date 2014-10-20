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

@interface WLEditSession ()

@property (nonatomic) BOOL hasChanges;

@property (strong, nonatomic) NSSet *properties;

@end

@implementation WLEditSession

@synthesize original = _original;
@synthesize changed = _changed;
@synthesize entry = _entry;

- (id)initWithEntry:(WLEntry *)entry properties:(NSSet *)properties {
    self = [super init];
    if (self) {
        _original = [NSMutableDictionary dictionary];
        _changed = [NSMutableDictionary dictionary];
        _entry = entry;
        self.properties = properties;
        for (WLEditSessionProperty *property in properties) {
            property->_editSession = self;
        }
        [self setup:self.original];
        [self setup:self.changed];
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

- (void)setup:(NSMutableDictionary *)dictionary {
    for (WLEditSessionProperty *property in self.properties) {
        id value = [_entry valueForKeyPath:property.keyPath];
        if (value) {
            [dictionary setObject:value forKey:property.keyPath];
        }
    }
}

- (void)apply:(NSMutableDictionary *)dictionary {
    for (WLEditSessionProperty *property in self.properties) {
        id value = [dictionary objectForKey:property.keyPath];
        if (value) {
            [_entry setValue:value forKeyPath:property.keyPath];
        }
    }
}

- (void)apply {
    [self apply:self.changed];
}

- (void)reset {
    [self apply:self.original];
}

- (void)clean {
    [_changed setDictionary:self.original];
    self.hasChanges = NO;
}

- (void)setHasChanges:(BOOL)hasChanges {
    if (_hasChanges != hasChanges) {
        _hasChanges = hasChanges;
        [self.delegate editSession:self hasChanges:hasChanges];
    }
}

- (id)valueForProperty:(NSString *)keyPath {
    return [self.changed objectForKey:keyPath];
}

- (void)setValue:(id)value forProperty:(NSString *)keyPath {
    [self.changed trySetObject:value forKey:keyPath];
    [self updateHasChangesFlag];
}

- (BOOL)isPropertyChanged:(NSString *)keyPath {
    for (WLEditSessionProperty *property in self.properties) {
        if ([property.keyPath isEqualToString:keyPath]) {
            return property.changed;
        }
    }
    return NO;
}

- (void)updateHasChangesFlag {
    for (WLEditSessionProperty *property in self.properties) {
        if (property.changed) {
            self.hasChanges = YES;
            break;
        }
    }
    self.hasChanges = NO;
}

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

- (BOOL)changed {
    return !self.comparator([_editSession->_original objectForKey:self.keyPath],[_editSession->_changed objectForKey:self.keyPath]);
}

@end
