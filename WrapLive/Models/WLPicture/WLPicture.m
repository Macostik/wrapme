//
//  WLPicture.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPicture.h"

@implementation WLPicture

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
}

@end
