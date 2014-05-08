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

typedef void (^WLBlock) (void);
typedef void (^WLObjectBlock) (id object);
typedef id (^WLReturnObjectBlock) (void);
typedef id (^WLMapObjectBlock) (id object);
typedef void (^WLFailureBlock) (NSError *error);
typedef id (^WLMapResponseBlock)(WLAPIResponse* response);
typedef void (^WLUserBlock) (WLUser *user);
typedef void (^WLWrapBlock) (WLWrap *wrap);
typedef void (^WLCandyBlock) (WLCandy *candy);
typedef void (^WLCommentBlock) (WLComment *comment);
typedef void (^WLContactBlock) (WLContact *contact);
typedef void (^WLArrayBlock) (NSArray *array);
typedef void (^WLDictionaryBlock) (NSDictionary *dictionary);
typedef void (^WLStringBlock) (NSString *string);
