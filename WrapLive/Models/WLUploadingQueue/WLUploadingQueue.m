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
#import "UIImage+Resize.h"
#import "WLWrapBroadcaster.h"

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

- (void)save {
	[WLDataCache cache].uploadingItems = self.items;
}

- (void)addItem:(WLUploadingItem *)item {
	[self.items addObject:item];
	[self save];
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
	[self save];
}

- (void)updateWrap:(WLWrap *)wrap {
	NSArray* candies = [self.items map:^id(WLUploadingItem* item) {
		if ([wrap isEqualToEntry:item.wrap]) {
			WLWrapDate* date = [wrap.dates firstObject];
			WLCandy* candy = [date.candies selectObject:^BOOL(WLCandy* candy) {
				return [candy isEqualToEntry:item.candy];
			}];
			if (candy == nil) {
				return item.candy;
			} else {
				[candy updateWithObject:item.candy];
			}
		}
		return nil;
	}];
	if ([candies count] > 0) {
		[wrap addCandies:candies];
	}
}

- (void)uploadImage:(UIImage *)image
			   wrap:(WLWrap *)wrap
			success:(WLObjectBlock)success
			failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache uploadingCache] setImage:image completion:^(NSString *path) {
		WLPicture* picture = [[WLPicture alloc] init];
		picture.large = path;
		[[WLImageCache uploadingCache] setImage:[image thumbnailImage:320] completion:^(NSString *path) {
			picture.medium = path;
			[[WLImageCache uploadingCache] setImage:[image thumbnailImage:160] completion:^(NSString *path) {
				picture.small = path;
				WLCandy* candy = [WLCandy imageWithPicture:picture];
				[[weakSelf addItemWithCandy:candy wrap:wrap] upload:success failure:failure];
				[wrap addCandy:candy];
			}];
		}];
	}];
}

- (void)uploadMessage:(NSString *)message
				 wrap:(WLWrap *)wrap
			  success:(WLObjectBlock)success
			  failure:(WLFailureBlock)failure {
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

- (void)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	WLPicture* picture = [self.candy.picture copy];
	self.operation = [self.wrap addCandy:self.candy success:^(WLCandy *candy) {
		if ([candy isImage]) {
			[[WLImageCache cache] setImageAtPath:picture.large withUrl:candy.picture.large];
			[[WLImageCache cache] setImageAtPath:picture.medium withUrl:candy.picture.medium];
			[[WLImageCache cache] setImageAtPath:picture.small withUrl:candy.picture.small];
		}
		[[WLUploadingQueue instance] removeItem:weakSelf];
		success(candy);
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
