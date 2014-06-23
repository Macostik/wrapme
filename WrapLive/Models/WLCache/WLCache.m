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

@interface WLCache ()

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

- (dispatch_queue_t)queue {
	if (!_queue) {
		_queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
	}
	return _queue;
}

- (NSMutableArray *)identifiers {
    if (!_identifiers) {
        NSString* directory = self.directory;
        if (directory) {
            _identifiers = [[[[NSFileManager defaultManager] enumeratorAtPath:directory] allObjects] mutableCopy];
        }
    }
    return _identifiers;
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

- (id)read:(NSString *)identifier path:(NSString *)path {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

- (void)write:(NSString *)identifier object:(id)object path:(NSString *)path {
    [NSKeyedArchiver archiveRootObject:object toFile:path];
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [self.directory stringByAppendingPathComponent:identifier];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
    return [self.identifiers containsObject:identifier];
}

- (id)objectWithIdentifier:(NSString*)identifier {
    return [self read:identifier path:[self pathWithIdentifier:identifier]];
}

- (void)objectWithIdentifier:(NSString*)identifier completion:(WLCacheReadCompletionBlock)completion {
	__weak typeof(self)weakSelf = self;
	run_getting_object_in_queue(self.queue, ^id{
		return [weakSelf objectWithIdentifier:identifier];
	}, completion);
}

- (void)setObject:(id)object withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion {
	if (!object) {
		return;
	}
	dispatch_async(self.queue, ^{
		NSString* path = [self pathWithIdentifier:identifier];
        [self write:identifier object:object path:path];
        if (![self.identifiers containsObject:identifier]) {
            [self.identifiers addObject:identifier];
        }
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
            
            self.identifiers = [[[[NSFileManager defaultManager] enumeratorAtPath:directory] allObjects] mutableCopy];
		}
	}
}

- (void)clear {
	NSString* directory = self.directory;
	NSDirectoryEnumerator* enumerator = [self.manager enumeratorAtPath:directory];
	for (NSString* file in enumerator) {
		[self.manager removeItemAtPath:[directory stringByAppendingPathComponent:file] error:NULL];
	}
    self.identifiers = [[[[NSFileManager defaultManager] enumeratorAtPath:directory] allObjects] mutableCopy];
}

@end
