//
//  WLCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCache.h"
#import "NSString+Documents.h"
#import "WLBlocks.h"

@interface WLCacheItem : NSObject

@property (nonatomic, strong) NSString* path;

@property (nonatomic) unsigned long long size;

@property (nonatomic, strong) NSDate* date;

@end

@implementation WLCacheItem @end

@interface WLCache ()

@property (strong, nonatomic) NSString* identifier;

@property (weak, nonatomic) WLCache* relativeCache;

@end

@implementation WLCache

@synthesize directory = _directory;

+ (instancetype)cache {
	return nil;
}

+ (instancetype)cacheWithIdentifier:(NSString *)identifier {
	return [self cacheWithIdentifier:identifier relativeCache:nil];
}

+ (instancetype)cacheWithIdentifier:(NSString *)identifier relativeCache:(WLCache *)relativeCache {
	WLCache* cache = [[self alloc] init];
	cache.relativeCache = relativeCache;
	cache.identifier = identifier;
	return cache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure {
	
}

- (void)setSize:(NSUInteger)size {
	_size = size;
	if (size > 0) {
		[self enqueueCheckSizePerforming];
	}
}

- (NSString *)directory {
	if (!_directory) {
		if (self.relativeCache) {
			_directory = [self.relativeCache.directory stringByAppendingPathComponent:self.identifier];
		} else {
			_directory = NSDocumentsDirectoryPath(self.identifier);
		}
	}
	if (![self.manager fileExistsAtPath:_directory]) {
		[self.manager createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	return _directory;
}

- (NSFileManager *)manager {
	return [NSFileManager defaultManager];
}

- (WLCacheReadObjectBlock)readObjectBlock {
	if (!_readObjectBlock) {
		_readObjectBlock = ^id (NSString* identifier, NSString* path) {
			return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		};
	}
	return _readObjectBlock;
}

- (WLCacheWriteObjectBlock)writeObjectBlock {
	if (!_writeObjectBlock) {
		_writeObjectBlock = ^(NSString* identifier, id object, NSString* path) {
			[NSKeyedArchiver archiveRootObject:object toFile:path];
		};
	}
	return _writeObjectBlock;
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [self.directory stringByAppendingPathComponent:identifier];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
	return [self.manager fileExistsAtPath:[self pathWithIdentifier:identifier]];
}

- (id)objectWithIdentifier:(NSString*)identifier {
	return self.readObjectBlock(identifier, [self pathWithIdentifier:identifier]);
}

- (void)objectWithIdentifier:(NSString*)identifier completion:(WLCacheReadCompletionBlock)completion {
	__weak typeof(self)weakSelf = self;
	run_getting_object(^id{
		return [weakSelf objectWithIdentifier:identifier];
	}, completion);
}

- (void)setObject:(id)object withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion {
	run_in_default_queue(^{
		NSString* path = [self pathWithIdentifier:identifier];
		self.writeObjectBlock(identifier, object, path);
		run_in_main_queue(^{
			if (completion) {
				completion(path);
			}
		});
		[self checkSizeAndClearIfNeededInBackground];
	});
}

- (void)setObject:(id)object withIdentifier:(NSString*)identifier {
	[self setObject:object withIdentifier:identifier completion:nil];
}

- (void)enqueueCheckSizePerforming {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSizeAndClearIfNeededInBackground) object:nil];
	[self performSelector:@selector(checkSizeAndClearIfNeededInBackground) withObject:nil afterDelay:0.5f];
}

- (void)checkSizeAndClearIfNeededInBackground {
	[self performSelectorInBackground:@selector(checkSizeAndClearIfNeeded) withObject:nil];
}

- (void)checkSizeAndClearIfNeeded {
	if (self.size > 0) {
		@autoreleasepool {
			NSString* directory = self.directory;
			
			NSDirectoryEnumerator* enumerator = [self.manager enumeratorAtPath:directory];
			NSUInteger size = 0;
			
			NSMutableArray* items = [NSMutableArray array];
			
			for (NSString* file in enumerator) {
				
				WLCacheItem* item = [[WLCacheItem alloc] init];
				item.path = [directory stringByAppendingPathComponent:file];
				
				NSDictionary* attributes = [self.manager attributesOfItemAtPath:item.path error:NULL];
				
				item.size = [attributes fileSize];
				
				item.date = [attributes fileCreationDate];
				
				size += item.size;
				
				[items addObject:item];
			}
			
			[items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
			
			while (size >= self.size) {
				WLCacheItem* item = [items firstObject];
				[self.manager removeItemAtPath:item.path error:NULL];
				size -= item.size;
				[items removeObject:item];
			}
		}
	}
}

- (void)clear {
	NSString* directory = self.directory;
	NSDirectoryEnumerator* enumerator = [self.manager enumeratorAtPath:directory];
	for (NSString* file in enumerator) {
		[self.manager removeItemAtPath:[directory stringByAppendingPathComponent:file] error:NULL];
	}
}

@end
