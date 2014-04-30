//
//  WLCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCache.h"
#import "NSString+Documents.h"

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

- (NSString *)directory {
	if (!_directory) {
		if (self.relativeCache) {
			_directory = [self.relativeCache.directory stringByAppendingPathComponent:self.identifier];
		} else {
			_directory = NSDocumentsDirectoryPath(self.identifier);
		}
	}
	if (![[NSFileManager defaultManager] fileExistsAtPath:_directory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	return _directory;
}

- (WLCacheReadObjectBlock)readObjectBlock {
	if (!_readObjectBlock) {
		_readObjectBlock = ^id (NSString* path) {
			return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		};
	}
	return _readObjectBlock;
}

- (WLCacheWriteObjectBlock)writeObjectBlock {
	if (!_writeObjectBlock) {
		_writeObjectBlock = ^(id object, NSString* path) {
			[NSKeyedArchiver archiveRootObject:object toFile:path];
		};
	}
	return _writeObjectBlock;
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [self.directory stringByAppendingPathComponent:identifier];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
	return [[NSFileManager defaultManager] fileExistsAtPath:[self pathWithIdentifier:identifier]];
}

- (id)objectWithIdentifier:(NSString*)identifier {
	return self.readObjectBlock([self pathWithIdentifier:identifier]);
}

- (void)objectWithIdentifier:(NSString*)identifier completion:(WLCacheReadCompletionBlock)completion {
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id object = [weakSelf objectWithIdentifier:identifier];
        dispatch_async(dispatch_get_main_queue(), ^{
			if (completion) {
				completion(object);
			}
        });
    });
}

- (void)setObject:(id)object withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString* path = [self pathWithIdentifier:identifier];
		self.writeObjectBlock(object, path);
        dispatch_async(dispatch_get_main_queue(), ^{
			if (completion) {
				completion(path);
			}
        });
    });
}

- (void)setObject:(id)object withIdentifier:(NSString*)identifier {
	[self setObject:object withIdentifier:identifier completion:nil];
}

- (void)clear {
	
}

@end
