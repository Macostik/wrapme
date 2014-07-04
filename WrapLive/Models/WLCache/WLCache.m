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
#import "NSArray+Additions.h"

@interface WLCacheItem : NSObject

@property (strong, nonatomic) NSString* identifier;

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
	return [[self alloc] initWithIdentifier:identifier relativeCache:relativeCache];
}

- (instancetype)initWithIdentifier:(NSString *)identifier relativeCache:(WLCache *)relativeCache {
    self = [super init];
    if (self) {
        _manager = [NSFileManager defaultManager];
        self.relativeCache = relativeCache;
        self.identifier = identifier;
        [self configure];
    }
    return self;
}

- (void)configure {
    NSString* identifier = self.identifier;
    if (identifier) {
        _queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
        if (self.relativeCache) {
            _directory = [self.relativeCache.directory stringByAppendingPathComponent:identifier];
        } else {
            _directory = NSDocumentsDirectoryPath(identifier);
        }
        if (![_manager fileExistsAtPath:_directory]) {
            [_manager createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        _identifiers = [NSMutableSet setWithArray:[[_manager enumeratorAtPath:_directory] allObjects]];
    }
}

- (void)setSize:(NSUInteger)size {
	_size = size;
	if (size > 0) {
		[self enqueueCheckSizePerforming];
	}
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
		[self enqueueCheckSizePerforming];
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
    NSString* directory = self.directory;
	if (self.size > 0 && directory) {
		@autoreleasepool {
			NSDirectoryEnumerator* enumerator = [_manager enumeratorAtPath:directory];
			unsigned long long size = 0;
			
			NSMutableArray* items = [NSMutableArray array];
			
			for (NSString* file in enumerator) {
				
				WLCacheItem* item = [[WLCacheItem alloc] init];
                item.identifier = file;
				item.path = [directory stringByAppendingPathComponent:file];
				
				NSDictionary* attributes = [_manager attributesOfItemAtPath:item.path error:NULL];
				
				item.size = [attributes fileSize];
				
				item.date = [attributes fileCreationDate];
				
				size += item.size;
				
				[items addObject:item];
			}
			
			[items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
			
			while (size >= self.size) {
				WLCacheItem* item = [items firstObject];
				[_manager removeItemAtPath:item.path error:NULL];
				size -= item.size;
				[items removeObject:item];
			}
            
            [self.identifiers removeAllObjects];
            [self.identifiers addObjectsFromArray:[items map:^id(WLCacheItem* item) {
                return item.identifier;
            }]];
		}
	}
}

- (void)clear {
	NSString* directory = self.directory;
	NSDirectoryEnumerator* enumerator = [_manager enumeratorAtPath:directory];
	for (NSString* file in enumerator) {
		[_manager removeItemAtPath:[directory stringByAppendingPathComponent:file] error:NULL];
	}
    [self.identifiers removeAllObjects];
}

@end
