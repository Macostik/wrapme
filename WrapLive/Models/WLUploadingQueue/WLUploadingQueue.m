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
#import "NSString+Additions.h"

@interface WLUploadingQueue ()

@property (strong, nonatomic) NSMutableArray* uploadings;

@end

@implementation WLUploadingQueue

@synthesize uploadings = _uploadings;

+ (instancetype)instance {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (NSMutableArray *)uploadings {
	if (!_uploadings) {
		_uploadings = [NSMutableArray arrayWithArray:[WLDataCache cache].uploadings];
	}
	if (!_uploadings) {
		_uploadings = [NSMutableArray array];
	}
	return _uploadings;
}

- (void)save {
	[WLDataCache cache].uploadings = [self.uploadings copy];
}

- (void)addUploading:(WLUploading *)uploading {
	[self.uploadings addObject:uploading];
	[self save];
}

- (WLUploading*)addUploadingWithCandy:(WLCandy *)candy wrap:(WLWrap *)wrap {
	WLUploading* uploading = [[WLUploading alloc] init];
	uploading.wrap = wrap;
	uploading.candy = candy;
	candy.uploading = uploading;
	[self addUploading:uploading];
	return uploading;
}

- (void)removeUploading:(WLUploading *)uploading {
	uploading.candy.uploading = nil;
	[self.uploadings removeObject:uploading];
	[self save];
}

- (void)updateWrap:(WLWrap *)wrap {
	NSArray* candies = [self.uploadings map:^id(WLUploading* item) {
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
	if (candies.nonempty) {
		[wrap addCandies:candies replaceMessage:NO];
	}
}

- (void)reviseCandy:(WLCandy *)candy {
	if (candy.identifier.nonempty && self.uploadings.nonempty) {
		NSUInteger count = [self.uploadings count];
		[self.uploadings removeObjectsWhileEnumerating:^BOOL(WLUploading* uploading) {
			return [candy.uploadIdentifier isEqualToString:uploading.candy.uploadIdentifier];
		}];
		if (count != [self.uploadings count]) {
			[self save];
		}
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
				[[weakSelf addUploadingWithCandy:candy wrap:wrap] upload:success failure:failure];
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
	[[weakSelf addUploadingWithCandy:candy wrap:wrap] upload:success failure:failure];
	[wrap addCandy:candy];
}

- (void)checkStatus {
	NSArray* identifiers = [self.uploadings map:^id(WLUploading* uploading) {
		return uploading.candy.uploadIdentifier;
	}];
	
	if (identifiers.nonempty) {
		__weak typeof(self)weakSelf = self;
		[[WLAPIManager instance] uploadStatus:identifiers success:^(NSArray *array) {
			NSMutableArray* uploadings = [weakSelf.uploadings mutableCopy];
			[uploadings removeObjectsWhileEnumerating:^BOOL(WLUploading* uploading) {
				return ![array containsObject:uploading.candy.uploadIdentifier];
			}];
			weakSelf.uploadings = uploadings;
			[weakSelf save];
		} failure:^(NSError *error) {
		}];
	}
}

@end

@implementation WLUploading
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
		[[WLUploadingQueue instance] removeUploading:weakSelf];
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
}

- (AFURLConnectionOperation *)operation {
	return _operation;
}

@end
