//
//  WLBlocks.h
//  moji
//
//  Created by Ravenpod on 08.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLAPIResponse;
@class WLCandy;
@class WLWrap;
@class WLUser;
@class WLAPIResponse;
@class WLComment;
@class WLAddressBookRecord;
@class WLAddressBookPhoneNumber;
@class WLAuthorization;
@class WLEntry;
@class WLMessage;
@class WLPicture;

typedef void (^WLBlock) (void);
typedef void (^WLObjectBlock) (id object);
typedef id (^WLReturnObjectBlock) (void);
typedef id (^WLMapObjectBlock) (id object);
typedef void (^WLFailureBlock) (NSError *error);
typedef id (^WLMapResponseBlock)(WLAPIResponse* response);
typedef void (^WLAuthorizationBlock) (WLAuthorization *authorization);
typedef void (^WLEntryBlock) (WLEntry *entry);
typedef void (^WLUserBlock) (WLUser *user);
typedef void (^WLWrapBlock) (WLWrap *wrap);
typedef void (^WLCandyBlock) (WLCandy *candy);
typedef void (^WLMessageBlock) (WLMessage *message);
typedef void (^WLCommentBlock) (WLComment *comment);
typedef void (^WLContactBlock) (WLAddressBookRecord *contact);
typedef void (^WLAddressBookPhoneNumberBlock) (WLAddressBookPhoneNumber *person);
typedef void (^WLArrayBlock) (NSArray *array);
typedef void (^WLSetBlock) (NSSet *set);
typedef void (^WLOrderedSetBlock) (NSOrderedSet *orderedSet);
typedef void (^WLDictionaryBlock) (NSDictionary *dictionary);
typedef void (^WLStringBlock) (NSString *string);
typedef void (^WLDataBlock) (NSData *data);
typedef void (^WLImageBlock) (UIImage *image);
typedef void (^WLPointBlock) (CGPoint point);
typedef void (^WLBooleanBlock) (BOOL flag);
typedef void(^WLIntegerBlock) (NSInteger index);
typedef id(^MapBlock)(id item);
typedef BOOL(^SelectBlock)(id item);
typedef void(^EnumBlock)(id item);
typedef BOOL(^EqualityBlock)(id first, id second);
typedef void (^WLImageFetcherBlock)(UIImage* image, BOOL cached);
typedef NSDate* (^WLDateFromEntryBlock)(WLEntry* entry);
typedef void (^WLGestureBlock)(UIGestureRecognizer *recognizer);
typedef void (^WLPictureBlock) (WLPicture *picture);
