//
//  UIImage+WLStoring.h
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WLStoring)

- (void)storeWithName:(NSString*)name completion:(void (^)(NSString* path))completion;

- (void)storeAsAvatar:(void (^)(NSString* path))completion;

- (void)storeAsCover:(void (^)(NSString* path))completion;

- (void)storeAsImage:(void (^)(NSString* path))completion;

+ (void)removeImageAtPath:(NSString*)path;

+ (void)removeAllTemporaryImages;

@end
