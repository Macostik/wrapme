//
//  WLArchivingObject.m
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import <objc/runtime.h>
#import "NSDate+Formatting.h"
#import "NSArray+Additions.h"
#import "WLSupportFunctions.h"
#import "WLBlocks.h"

@implementation WLArchivingObject

+ (NSArray*)properties {
	NSArray* properties = objc_getAssociatedObject(self, "recursive_archiving_properties");
	if (!properties) {
		Class currentClass = self;
		Class terminatingClass = [WLArchivingObject class];
		NSMutableArray* _properties = [NSMutableArray array];
		while (currentClass != terminatingClass) {
			unsigned int count;
			objc_property_t *propertyList = class_copyPropertyList(currentClass, &count);
			if (count > 0) {
				for (NSInteger i = count - 1; i >= 0; --i) {
					const char *property_name = property_getName(propertyList[i]);
					[_properties addObject:((__bridge NSString*)__CFStringMakeConstantString(property_name))];
				}
			}
			if (propertyList != NULL) {
				free(propertyList);
			}
			currentClass = class_getSuperclass(currentClass);
		}
		properties = [_properties copy];
		objc_setAssociatedObject(self, "recursive_archiving_properties", properties, OBJC_ASSOCIATION_RETAIN);
	}
	return properties;
}

+ (void)properties:(void (^)(NSString* property))enumerationBlock {
    NSArray* properties = [self properties];
    @synchronized(properties) {
        [properties all:enumerationBlock];
    }
}

- (NSArray*)properties {
	return [[self class] properties];
}

- (void)properties:(void (^)(NSString* property))enumerationBlock {
	[[self class] properties:enumerationBlock];
}

- (instancetype)updateWithObject:(id)object {
	Class class = [object class];
	__weak typeof(self)weakSelf = self;
	if (class == [self class]) {
		[self properties:^(NSString *property) {
			id value = [object valueForKey:property];
			if (value) {
				[weakSelf setValue:value forKey:property];
			}
		}];
	}
	return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [self init];
	if (self) {
        __weak typeof(self)weakSelf = self;
		[self properties:^(NSString *property) {
            if (weakSelf) {
                id value = [aDecoder decodeObjectForKey:property];
                if (value) {
                    [weakSelf setValue:value forKey:property];
                }
            }
		}];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    __weak typeof(self)weakSelf = self;
	[self properties:^(NSString *property) {
        if (weakSelf) {
            [aCoder encodeObject:[weakSelf valueForKey:property] forKey:property];
        }
	}];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	Class class = [self class];
	__weak typeof(self)weakSelf = self;
	WLArchivingObject* copy = [[class allocWithZone:zone] init];
	[self properties:^(NSString *property) {
		id value = [weakSelf valueForKey:property];
		if (value) {
			if ([value respondsToSelector:@selector(copyWithZone:)]) {
				value = [value copy];
			}
			[copy setValue:value forKey:property];
		}
	}];
	return copy;
}

@end

@implementation NSObject (WLArchivingObject)

- (NSData *)archive {
	return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (void)archive:(void (^)(NSData *))completion {
	run_getting_object(^id{
		return [self archive];
	}, completion);
}

- (void)archiveToFileAtPath:(NSString*)path {
	[NSKeyedArchiver archiveRootObject:self toFile:path];
}

- (void)archiveToFileAtPath:(NSString*)path completion:(void (^)(void))completion {
	run_with_completion(^{
		[self archiveToFileAtPath:path];
	}, completion);
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

+ (void)unarchive:(NSData *)data completion:(void (^)(id))completion {
	run_getting_object(^id{
		return [self unarchive:data];
	}, completion);
}

+ (id)unarchiveFromFileAtPath:(NSString*)path {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void)unarchiveFromFileAtPath:(NSString*)path completion:(void (^)(id object))completion {
	run_getting_object(^id{
		return [self unarchiveFromFileAtPath:path];
	}, completion);
}

@end
