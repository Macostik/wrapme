//
//  WLArchivingObject.m
//  meWrap
//
//  Created by Ravenpod on 21.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"
#import <objc/runtime.h>

@implementation WLArchivingObject

+ (NSArray*)archivableProperties {
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

+ (void)archivableProperties:(void (^)(NSString* property))enumerationBlock {
    NSArray* properties = [self archivableProperties];
    @synchronized(properties) {
        for (NSString *property in properties) {
            if (enumerationBlock) enumerationBlock(property);
        }
    }
}

- (NSArray*)archivableProperties {
	return [[self class] archivableProperties];
}

- (void)archivableProperties:(void (^)(NSString* property))enumerationBlock {
	[[self class] archivableProperties:enumerationBlock];
}

- (instancetype)updateWithObject:(id)object {
	Class class = [object class];
	__weak typeof(self)weakSelf = self;
	if (class == [self class]) {
		[self archivableProperties:^(NSString *property) {
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
		[self archivableProperties:^(NSString *property) {
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
	[self archivableProperties:^(NSString *property) {
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
	[self archivableProperties:^(NSString *property) {
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id object = [self archive];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(object);
        });
    });
}

- (void)archiveToFileAtPath:(NSString*)path {
	[NSKeyedArchiver archiveRootObject:self toFile:path];
}

- (void)archiveToFileAtPath:(NSString*)path completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self archiveToFileAtPath:path];
        dispatch_async(dispatch_get_main_queue(), completion);
    });
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id object = [self unarchive:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(object);
        });
    });
}

+ (id)unarchiveFromFileAtPath:(NSString*)path {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void)unarchiveFromFileAtPath:(NSString*)path completion:(void (^)(id object))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id object = [self unarchiveFromFileAtPath:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(object);
        });
    });
}

@end
