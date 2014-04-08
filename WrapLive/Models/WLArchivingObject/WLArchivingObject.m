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

static inline void EnumeratePropertiesOfClass(Class class, void (^enumerationBlock)(NSString* property)) {
	if (class != [NSObject class]) {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(class, &count);
		if (count > 0) {
			for (NSInteger i = count - 1; i >= 0; --i) {
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

+ (NSMutableDictionary *)mapping {
	return [NSMutableDictionary dictionary];
}

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:[self mapping]];
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
	return [[self alloc] initWithDictionary:dict error:NULL];
}

- (instancetype)updateWithDictionary:(NSDictionary *)dict {
	return [self updateWithObject:[[self class] modelWithDictionary:dict]];
}

- (instancetype)updateWithObject:(id)object {
	Class class = [object class];
	__weak typeof(self)weakSelf = self;
	if (class == [self class]) {
		EnumeratePropertiesOfClass(class, ^(NSString *property) {
			id value = [object valueForKey:property];
			if (value) {
				[weakSelf setValue:value forKey:property];
			}
		});
	}
	return self;
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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	Class class = [self class];
	__weak typeof(self)weakSelf = self;
	WLArchivingObject* copy = [[class allocWithZone:zone] init];
	EnumeratePropertiesOfClass(class, ^(NSString *property) {
		id value = [weakSelf valueForKey:property];
		if (value) {
			[copy setValue:value forKey:property];
		}
	});
	return copy;
}

@end

@implementation JSONValueTransformer (NSDate)

- (NSDate*)NSDateFromNSString:(NSString*)string {
	NSDate* date = [string dateWithFormat:@"yyyy-MM-dd'T'HH:mm:ss.000Z"];
	if (date == nil) {
		date = [NSDate dateWithTimeIntervalSince1970:[string doubleValue]];
	}
	return date;
}

- (NSString*)JSONObjectFromNSDate:(NSDate*)date {
	return [NSString stringWithFormat:@"%f",[date timeIntervalSince1970]];
}

- (NSDate *)NSDateFromNSNumber:(NSNumber *)number {
	return [NSDate dateWithTimeIntervalSince1970:[number doubleValue]];
}

@end
