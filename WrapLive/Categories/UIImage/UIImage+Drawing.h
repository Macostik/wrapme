//
//  UIImage+Drawing.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *WLAlbumName = @"wrapLive";

@interface UIImage (Drawing)

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size opaque:(BOOL)opaque drawing:(void(^)(CGSize size))drawing;

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size drawing:(void(^)(CGSize size))drawing;

- (void)save:(NSMutableDictionary*)metadata;

- (void)save:(NSMutableDictionary*)metadata completion:(void (^)(void))completion failure:(void (^)(NSError*))failure;

@end
