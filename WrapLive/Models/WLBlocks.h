//
//  WLBlocks.h
//  WrapLive
//
//  Created by Sergey Maximenko on 08.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLAPIResponse;
@class WLCandy;
@class WLWrap;
@class WLUser;
@class WLAPIResponse;
@class WLComment;
@class WLContact;
@class WLAuthorization;
@class WLEntry;
@class WLMessage;

typedef void (^WLBlock) (void);
typedef void (^WLObjectBlock) (id object);
typedef id (^WLReturnObjectBlock) (void);
typedef id (^WLMapObjectBlock) (id object);
typedef void (^WLFailureBlock) (NSError *error);
typedef id (^WLMapResponseBlock)(WLAPIResponse* response);
typedef void (^WLAuthorizationBlock) (WLAuthorization *authorization);
typedef void (^WLUserBlock) (WLUser *user);
typedef void (^WLWrapBlock) (WLWrap *wrap);
typedef void (^WLCandyBlock) (WLCandy *candy);
typedef void (^WLMessageBlock) (WLMessage *message);
typedef void (^WLCommentBlock) (WLComment *comment);
typedef void (^WLContactBlock) (WLContact *contact);
typedef void (^WLArrayBlock) (NSArray *array);
typedef void (^WLOrderedSetBlock) (NSOrderedSet *orderedSet);
typedef void (^WLDictionaryBlock) (NSDictionary *dictionary);
typedef void (^WLStringBlock) (NSString *string);
typedef void (^WLDataBlock) (NSData *data);
typedef void (^WLPointBlock) (CGPoint point);
typedef void (^WLBooleanBlock) (BOOL flag);
typedef void(^WLIntegerBlock) (NSInteger index);
typedef id(^MapBlock)(id item);
typedef BOOL(^SelectBlock)(id item);
typedef void(^EnumBlock)(id item);
typedef BOOL(^EqualityBlock)(id first, id second);
typedef void (^WLImageFetcherBlock)(UIImage* image, BOOL cached);
typedef NSDate* (^WLDateFromEntryBlock)(WLEntry* entry);
typedef void (^PubNubMessageBlock)(PNMessage *message);

static inline void run_in_default_queue(dispatch_block_t block) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline void run_in_background_queue(dispatch_block_t block) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

static inline void run_in_main_queue(dispatch_block_t block) {
	dispatch_async(dispatch_get_main_queue(), block);
}

static inline void run_with_completion(dispatch_block_t block, dispatch_block_t completion) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (block) {
			block();
		}
		run_in_main_queue(completion);
	});
}

static inline void run_getting_object_in_queue(dispatch_queue_t queue, WLReturnObjectBlock block, WLObjectBlock completion) {
	dispatch_async(queue, ^{
		id object = nil;
		if (block) {
			object = block();
		}
		if (completion) {
			run_in_main_queue(^{
				completion(object);
			});
		}
    });
}

static inline void run_getting_object(WLReturnObjectBlock block, WLObjectBlock completion) {
	run_getting_object_in_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block, completion);
}

static inline void run_getting_object_in_background(WLReturnObjectBlock block, WLObjectBlock completion) {
	run_getting_object_in_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block, completion);
}

static inline void run_after(NSTimeInterval after, dispatch_block_t block) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

static inline void run_loop(NSUInteger count, dispatch_block_t block) {
	while (count > 0) {
        --count;
        block();
    }
}
