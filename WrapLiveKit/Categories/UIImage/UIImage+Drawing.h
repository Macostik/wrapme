//
//  UIImage+Drawing.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *WLAlbumName = @"MOJI";

@interface UIImage (Drawing)

+ (UIImage*)draw:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale drawing:(void(^)(CGSize size))drawing;

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size opaque:(BOOL)opaque drawing:(void(^)(CGSize size))drawing;

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size drawing:(void(^)(CGSize size))drawing;

- (void)save:(NSMutableDictionary*)metadata;

- (void)save:(NSMutableDictionary*)metadata completion:(void (^)(void))completion failure:(void (^)(NSError*))failure;

- (void)writeToPNGFile:(NSString*)path atomically:(BOOL)atomically;

+ (UIImage*)gradient:(CGSize)size;

@end
