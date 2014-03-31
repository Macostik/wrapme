//
//  WLEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"
#import "WLSession.h"
#import "WLUser.h"

@implementation WLEntry

+ (instancetype)entry {
	WLEntry* entry = [[self alloc] init];
	entry.createdAt = [NSDate date];
	entry.modified = [NSDate date];
	entry.author = [WLSession user];
	return entry;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end

@implementation NSArray (WLEntrySorting)

+ (NSArray*)modifiedDescriptors {
	static NSArray* descriptors = nil;
	if (!descriptors) {
		descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modified" ascending:NO]];
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
