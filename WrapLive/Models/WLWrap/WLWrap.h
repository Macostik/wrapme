//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLWrapEntry;

@protocol WLWrapEntry @end

@interface WLWrap : WLEntry

@property (strong, nonatomic) NSArray<WLWrapEntry>* entries;
@property (strong, nonatomic) NSString* name;

- (void)addEntry:(WLWrapEntry*)entry;

@end
