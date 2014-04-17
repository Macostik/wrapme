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
#import "UIImage+WLStoring.h"

@interface WLUploadingQueue ()

@property (strong, nonatomic) NSMutableArray* items;

@end

@implementation WLUploadingQueue

+ (instancetype)instance {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
		[UIImage removeAllTemporaryImages];
	});
    return instance;
}

- (NSMutableArray *)items {
	if (!_items) {
		_items = [NSMutableArray array];
	}
	return _items;
}

- (void)addItem:(WLUploadingItem *)item {
	[self.items addObject:item];
}

- (WLUploadingItem*)addItemWithCandy:(WLCandy *)candy wrap:(WLWrap *)wrap {
	WLUploadingItem* item = [[WLUploadingItem alloc] init];
	item.wrap = wrap;
	item.candy = candy;
	[self addItem:item];
	return item;
}

- (void)removeItem:(WLUploadingItem *)item {
	item.candy.uploadingItem = nil;
	[self.items removeObject:item];
}

- (void)addCandiesToWrapIfNeeded:(WLWrap *)wrap {
	NSMutableArray* candies = [NSMutableArray array];
	
	for (WLUploadingItem* item in self.items) {
		if ([wrap isEqualToWrap:item.wrap]) {
			WLWrapDate* date = [wrap.dates firstObject];
			BOOL containsCandy = [date.candies containsObject:item.candy
													  byBlock:^BOOL(WLCandy* first, WLCandy* second) {
														  return [first isEqualToCandy:second];
													  }];
			if (!containsCandy) {
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
	[image storeAsImage:^(NSString *path) {
		WLCandy* candy = [WLCandy imageWithFileAtPath:path];
		WLUploadingItem* item = [weakSelf addItemWithCandy:candy wrap:wrap];
		item.operation = [[WLAPIManager instance] addCandy:candy toWrap:wrap success:^(id object) {
			[UIImage removeImageAtPath:path];
			[weakSelf removeItem:item];
			success(object);
		} failure:^(NSError *error) {
			[UIImage removeImageAtPath:path];
			[weakSelf removeItem:item];
			[wrap removeCandy:candy];
			failure(error);
		}];
		candy.uploadingItem = item;
		[wrap addCandy:candy];
	}];
}

- (void)uploadMessage:(NSString *)message
				 wrap:(WLWrap *)wrap
			  success:(WLAPIManagerSuccessBlock)success
			  failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	WLCandy* candy = [WLCandy chatMessageWithText:message];
	WLUploadingItem* item = [weakSelf addItemWithCandy:candy wrap:wrap];
	item.operation = [[WLAPIManager instance] addCandy:candy toWrap:wrap success:^(id object) {
		[weakSelf removeItem:item];
		success(object);
	} failure:^(NSError *error) {
		[weakSelf removeItem:item];
		[wrap removeCandy:candy];
		failure(error);
	}];
	candy.uploadingItem = item;
	[wrap addCandy:candy];
}

@end

@implementation WLUploadingItem

- (void)setOperation:(AFURLConnectionOperation *)operation {
	_progress = 0;
	__weak typeof(self)weakSelf = self;
	[operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
		weakSelf.progress = ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
		weakSelf.progress = ((float)totalBytesRead/(float)totalBytesExpectedToRead);
	}];
}

- (void)setProgress:(float)progress {
	_progress = progress;
	if (self.progressChangeBlock) {
		self.progressChangeBlock(progress);
	}
}

@end
