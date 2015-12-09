//
//  NSArray+WLCollection.h
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

@interface NSArray (WLCollection)

- (instancetype)where:(NSString *)predicateFormat, ...;

@end

@interface NSSet (WLCollection)

- (instancetype)where:(NSString *)predicateFormat, ...;

@end