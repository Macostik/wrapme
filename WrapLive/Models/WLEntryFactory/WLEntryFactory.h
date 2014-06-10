//
//  WLEntryFactory.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/10/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLEntry;

@interface WLEntryFactory : NSObject

+ (WLEntry*)entry:(WLEntry*)entry;

@end
