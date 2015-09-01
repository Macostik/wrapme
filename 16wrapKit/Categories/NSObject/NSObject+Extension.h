//
//  NSObject+Extension.h
//  moji
//
//  Created by Ravenpod on 8/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Extension)

- (void)enqueueSelectorPerforming:(SEL)aSelector;

- (void)enqueueSelectorPerforming:(SEL)aSelector afterDelay:(NSTimeInterval)delay;

- (void)enqueueSelectorPerforming:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay;

@end
