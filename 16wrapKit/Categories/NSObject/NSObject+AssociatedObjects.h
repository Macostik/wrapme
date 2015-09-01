//
//  NSObject+AssociatedObjects.h
//  moji
//
//  Created by Ravenpod on 12.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AssociatedObjects)

- (id)associatedObjectForKey:(const char *)key;

- (void)setAssociatedObject:(id)object forKey:(const char *)key;

@end
