//
//  WLDispatch.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLDispatch : NSObject

@property (weak, nonatomic) id target;

@property (nonatomic) SEL selector;

+ (instancetype)dispatch:(id)target selector:(SEL)selector;

- (id)initWithTarget:(id)target selector:(SEL)selector;

- (void)send;

@end
