//
//  WLPicture.h
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import "WLBlocks.h"

@interface WLPicture : WLArchivingObject

@property (strong, nonatomic) NSString* large;
@property (strong, nonatomic) NSString* medium;
@property (strong, nonatomic) NSString* small;

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion;

- (NSString*)anyUrl;

@end
