//
//  NSObject+AssociatedObjects.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AssociatedObjects)

- (id)associatedObjectForKey:(const char *)key;

- (void)setAssociatedObject:(id)object forKey:(const char *)key;

@end
