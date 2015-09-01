//
//  StreamIndex.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamIndex.h"

@implementation StreamIndex

+ (instancetype)index:(NSUInteger)value {
    StreamIndex *index = [[self alloc] init];
    index.value = value;
    return index;
}

- (instancetype)add:(NSUInteger)value {
    if (self.next) {
        [self.next add:value];
    } else {
        self.next = [StreamIndex index:value];
    }
    return self;
}

- (NSUInteger)section {
    return self.value;
}

- (NSUInteger)item {
    return self.next.value;
}

- (instancetype)copy {
    return [super copy];
}

- (id)copyWithZone:(NSZone *)zone {
    StreamIndex *index = [[StreamIndex allocWithZone:zone] init];
    index.value = self.value;
    if (self.next) {
        index.next = [self.next copy];
    }
    return index;
}

@end
