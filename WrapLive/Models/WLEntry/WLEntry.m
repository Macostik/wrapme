//
//  WLEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@implementation WLEntry

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"created_at_in_epoch":@"createdAt",
									@"updated_at_in_epoch":@"updatedAt"}];
}

+ (instancetype)entry {
	WLEntry* entry = [[self alloc] init];
	entry.createdAt = [NSDate date];
	entry.updatedAt = [NSDate date];
	return entry;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
	self = [super initWithDictionary:dict error:err];
	if (self) {
		self.picture = [[WLPicture alloc] initWithDictionary:dict error:err];
	}
	return self;
}

- (WLPicture *)picture {
	if (!_picture) {
		_picture = [[WLPicture alloc] init];
	}
	return _picture;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end

@implementation NSArray (WLEntrySorting)

+ (NSArray*)modifiedDescriptors {
	static NSArray* descriptors = nil;
	if (!descriptors) {
		descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
	}
	return descriptors;
}

- (NSArray *)sortedEntries {
	return [self sortedArrayUsingDescriptors:[NSArray modifiedDescriptors]];
}

@end

@implementation NSMutableArray (WLEntrySorting)

- (void)sortEntries {
	[self sortUsingDescriptors:[NSArray modifiedDescriptors]];
}

@end
