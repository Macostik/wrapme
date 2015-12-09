//
//  NSArray+WLCollection.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "NSArray+WLCollection.h"

@implementation NSArray (WLCollection)

- (instancetype)where:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return result;
}

@end

@implementation NSSet (WLCollection)

- (instancetype)where:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return result;
}

@end
