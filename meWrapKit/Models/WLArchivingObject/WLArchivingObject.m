//
//  WLArchivingObject.m
//  meWrap
//
//  Created by Ravenpod on 21.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"

@implementation WLArchivingObject

+ (NSSet*)archivableProperties {
	return nil;
}

- (instancetype)updateWithObject:(id)object {
	Class class = [object class];
	if (class == [self class]) {
        for (NSString *property in [class archivableProperties]) {
            id value = [object valueForKey:property];
            if (value) {
                [self setValue:value forKey:property];
            }
        }
	}
	return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [self init];
	if (self) {
        for (NSString *property in [[self class] archivableProperties]) {
            id value = [aDecoder decodeObjectForKey:property];
            if (value) {
                [self setValue:value forKey:property];
            }
        }
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *property in [[self class] archivableProperties]) {
        [aCoder encodeObject:[self valueForKey:property] forKey:property];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	Class class = [self class];
	__weak typeof(self)weakSelf = self;
	WLArchivingObject* copy = [[class allocWithZone:zone] init];
    for (NSString *property in [class archivableProperties]) {
        id value = [weakSelf valueForKey:property];
        if (value) {
            if ([value respondsToSelector:@selector(copyWithZone:)]) {
                value = [value copy];
            }
            [copy setValue:value forKey:property];
        }
    }
	return copy;
}

@end

@implementation NSObject (WLArchivingObject)

- (NSData *)archive {
	return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+ (id)unarchive:(NSData *)data {
	if (data) {
		id object = nil;
		@try {
			object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		} @catch (NSException *exception) {
		} @finally { }
		return object;
	}
	else {
		return nil;
	}
}

@end
