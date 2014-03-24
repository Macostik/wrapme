//
//  WLArchivingObject.m
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import <objc/runtime.h>

static inline void EnumeratePropertiesOfClass(Class class, void (^enumerationBlock)(NSString* property)) {
	if (class != [NSObject class]) {
		NSUInteger count;
		objc_property_t *properties = class_copyPropertyList(class, &count);
		if (count > 0) {
			for (int i = count - 1; i >= 0; --i) {
				const char *property_name = property_getName(properties[i]);
				enumerationBlock([NSString stringWithCString:property_name encoding:NSASCIIStringEncoding]);
			}
		}
		
		if (properties != NULL) {
			free(properties);
		}
		
		EnumeratePropertiesOfClass(class_getSuperclass(class), enumerationBlock);
	}
}

@implementation WLArchivingObject

- (NSData *)data {
	return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (void)data:(void (^)(NSData *))completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    NSData *data = [self data];
	    dispatch_async(dispatch_get_main_queue(), ^{
	        if (completion) {
	            completion(data);
			}
		});
	});
}

+ (id)objectWithData:(NSData *)data {
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

+ (void)objectWithData:(NSData *)data completion:(void (^)(id))completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    id object = [self objectWithData:data];
	    dispatch_async(dispatch_get_main_queue(), ^{
	        if (completion) {
	            completion(object);
			}
		});
	});
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [self init];
	if (self) {
		EnumeratePropertiesOfClass([self class], ^ (NSString* property) {
			id value = [aDecoder decodeObjectForKey:property];
			if (value) {
				[self setValue:value forKey:property];
			}
		});
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	EnumeratePropertiesOfClass([self class], ^ (NSString* property) {
		[aCoder encodeObject:[self valueForKey:property] forKey:property];
	});
}

@end
