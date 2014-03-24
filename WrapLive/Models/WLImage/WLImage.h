//
//  WLImage.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

@interface WLImage : WLWrapEntry

@property (strong, nonatomic) NSString* url;
@property (strong, nonatomic) NSString* thumbnail;

@end
