//
//  StreamIndex.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamIndex : NSObject <NSCopying>

@property (nonatomic) NSUInteger value;

@property (strong, nonatomic) StreamIndex *next;

@property (readonly, nonatomic) NSUInteger section;

@property (readonly, nonatomic) NSUInteger item;

+ (instancetype)index:(NSUInteger)value;

- (instancetype)add:(NSUInteger)value;

- (instancetype)copy;

@end
