//
//  Blocks.h
//  meWrap
//
//  Created by Ravenpod on 08.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^Block) (void);
typedef void (^ObjectBlock) (id __nullable object);
typedef void (^FailureBlock) (NSError * __nullable error);
typedef void (^ArrayBlock) (NSArray * __nullable array);
typedef void (^SetBlock) (NSSet * __nullable set);
typedef void (^ImageBlock) (UIImage * __nullable image);
typedef void (^BooleanBlock) (BOOL flag);

