//
//  UIImageView+ImageLoading.h
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (ImageLoading)

@property (nonatomic) NSString* imageUrl;

- (void)setImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached, NSError* error))completion;

@end
