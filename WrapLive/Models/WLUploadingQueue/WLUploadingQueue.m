//
//  WLUploadingQueue.m
//  WrapLive
//
//  Created by Sergey Maximenko on 14.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUploadingQueue.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "NSArray+Additions.h"
#import "WLWrapDate.h"
#import "WLDataCache.h"
#import "WLImageCache.h"

@interface WLUploadingQueue ()

@property (strong, nonatomic) NSMutableArray* items;

@end

@implementation WLUploadingQueue

@synthesize items = _items;

+ (instancetype)instance {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (NSMutableArray *)items {
	if (!_items) {
		_items = [NSMutableArray arrayWithArray:[WLDataCache cache].uploadingItems];
	}
	if (!_items) {
		_items = [NSMutableArray array];
	}
	return _items;
}

- (void)addItem:(WLUploadingItem *)item {
	[self.items addObject:item];
	[WLDataCache cache].uploadingItems = self.items;
}

- (WLUploadingItem*)addItemWithCandy:(WLCandy *)candy wrap:(WLWrap *)wrap {
	WLUploadingItem* item = [[WLUploadingItem alloc] init];
	item.wrap = wrap;
	item.candy = candy;
	candy.uploadingItem = item;
	[self addItem:item];
	return item;
}

- (void)removeItem:(WLUploadingItem *)item {
	item.candy.uploadingItem = nil;
	[self.items removeObject:item];
	[WLDataCache cache].uploadingItems = self.items;
}

- (void)updateWrap:(WLWrap *)wrap {
	NSMutableArray* candies = [NSMutableArray array];
	
	for (WLUploadingItem* item in self.items) {
		if ([wrap isEqualToWrap:item.wrap]) {
			WLWrapDate* date = [wrap.dates firstObject];
			BOOL contains = [date.candies containsObject:item.candy byBlock:^BOOL(WLCandy* first, WLCandy* second) {
														  return [first isEqualToCandy:second];
													  }];
			if (!contains) {
				[candies addObject:item.candy];
			}
		}
	}
	
	if ([candies count] > 0) {
		[wrap edit:^BOOL(WLWrap *wrap) {
			for (WLCandy* candy in candies) {
				[wrap addCandy:candy];
			}
			return YES;
		}];
	}
}

- (void)uploadImage:(UIImage *)image
			   wrap:(WLWrap *)wrap
			success:(WLAPIManagerSuccessBlock)success
			failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache uploadingCache] setImage:image completion:^(NSString *path) {
		WLCandy* candy = [WLCandy imageWithFileAtPath:path];
		[[weakSelf addItemWithCandy:candy wrap:wrap] upload:success failure:failure];
		[wrap addCandy:candy];
	}];
}

- (void)uploadMessage:(NSString *)message
				 wrap:(WLWrap *)wrap
			  success:(WLAPIManagerSuccessBlock)success
			  failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	WLCandy* candy = [WLCandy chatMessageWithText:message];
	[[weakSelf addItemWithCandy:candy wrap:wrap] upload:success failure:failure];
	[wrap addCandy:candy];
}

@end

@implementation WLUploadingItem
{
	__weak AFURLConnectionOperation* _operation;
}

- (void)upload:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	self.operation = [[WLAPIManager instance] addCandy:self.candy wrap:self.wrap success:^(id object) {
		[[WLUploadingQueue instance] removeItem:weakSelf];
		success(object);
	} failure:^(NSError *error) {
		[weakSelf setOperation:nil];
		[weakSelf.candy broadcastChange];
		failure(error);
	}];
	[self.candy broadcastChange];
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
	_operation = operation;
	_progress = 0;
	if (operation) {
		__weak typeof(self)weakSelf = self;
		[operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
			weakSelf.progress = ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
		}];
		[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
			weakSelf.progress = ((float)totalBytesRead/(float)totalBytesExpectedToRead);
		}];
	}
}

- (AFURLConnectionOperation *)operation {
	return _operation;
}

- (void)setProgress:(float)progress {
	_progress = progress;
	if (self.progressChangeBlock) {
		self.progressChangeBlock(progress);
	}
}

@end
