//
//  WLCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCache.h"
#import "NSString+Documents.h"
#import "NSArray+Additions.h"
#import "UIDevice+SystemVersion.h"

@interface WLCacheItem : NSObject

@property (strong, nonatomic) NSString* identifier;

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
        _manager = [[NSFileManager alloc] init];
        self.relativeCache = relativeCache;
        self.identifier = identifier;
        [self configure];
        [_manager changeCurrentDirectoryPath:_directory];
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
        [self fetchIdentifiers];
    }
}

- (void)fetchIdentifiers {
    _identifiers = [NSMutableSet setWithArray:[_manager contentsOfDirectoryAtPath:_directory error:NULL]];
}

- (void)setSize:(NSUInteger)size {
	_size = size;
	if (size > 0) {
		[self enqueueCheckSizePerforming];
	}
}

- (id)read:(NSString *)identifier {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[_manager contentsAtPath:identifier]];
}

- (void)write:(NSString *)identifier object:(id)object {
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (data) {
        if (SystemVersionGreaterThanOrEqualTo8()) {
            [data writeToFile:[[_manager currentDirectoryPath] stringByAppendingPathComponent:identifier] atomically:YES];
        } else {
            [_manager createFileAtPath:identifier contents:data attributes:nil];
        }
    }
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [self.directory stringByAppendingPathComponent:identifier];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
    return [self.identifiers containsObject:identifier];
}

- (id)objectWithIdentifier:(NSString*)identifier {
    return [self read:identifier];
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
        [self write:identifier object:object];
        [self.identifiers addObject:identifier];
		run_in_main_queue(^{
			if (completion) {
				completion(identifier);
			}
            [self enqueueCheckSizePerforming];
		});
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
    static BOOL checking = NO;
    NSUInteger limitSize = self.size;
    if (!checking && limitSize > 0) {
        checking = YES;
        __weak typeof(self)weakSelf = self;
        run_in_background_queue(^{
            
            unsigned long long size = 0;
            id items = [_manager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:_directory isDirectory:YES] includingPropertiesForKeys:@[NSURLTotalFileAllocatedSizeKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL];
            for (NSURL *item in items) {
                NSNumber *s = nil;
                [item getResourceValue:&s forKey:NSURLTotalFileAllocatedSizeKey error:NULL];
                size += [s unsignedLongLongValue];
            }
            if (size < limitSize) {
                checking = NO;
                return;
            }
            
            items = [items mutableCopy];
            
            [items sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSURL* obj1, NSURL* obj2) {
                NSDate *d1 = nil;
                [obj1 getResourceValue:&d1 forKey:NSURLCreationDateKey error:NULL];
                NSDate *d2 = nil;
                [obj2 getResourceValue:&d2 forKey:NSURLCreationDateKey error:NULL];
                return [d1 compare:d2];
            }];
            
            while (size >= limitSize) {
                NSURL* item = [items firstObject];
                NSNumber *s = nil;
                [item getResourceValue:&s forKey:NSURLTotalFileAllocatedSizeKey error:NULL];
                [_manager removeItemAtURL:item error:NULL];
                size -= [s unsignedLongLongValue];
                [items removeObject:item];
            }
            
            run_in_main_queue(^{
                [weakSelf fetchIdentifiers];
                checking = NO;
            });
        });
    }
}

- (void)clear {
    NSMutableSet* identifiers = self.identifiers;
    for (NSString* identifier in identifiers) {
        [_manager removeItemAtPath:identifier error:NULL];
    }
    [identifiers removeAllObjects];
}

@end
