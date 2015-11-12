//
//  WLBlocks.h
//  meWrap
//
//  Created by Ravenpod on 08.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^WLBlock) (void);
typedef void (^WLObjectBlock) (id __nullable object);
typedef void (^WLFailureBlock) (NSError * __nullable error);
typedef void (^WLArrayBlock) (NSArray * __nullable array);
typedef void (^WLSetBlock) (NSSet * __nullable set);
typedef void (^WLOrderedSetBlock) (NSOrderedSet * __nullable orderedSet);
typedef void (^WLDictionaryBlock) (NSDictionary * __nullable dictionary);
typedef void (^WLImageBlock) (UIImage * __nullable image);
typedef void (^WLBooleanBlock) (BOOL flag);

