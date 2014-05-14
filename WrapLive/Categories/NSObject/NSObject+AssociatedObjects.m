//
//  NSObject+AssociatedObjects.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSObject+AssociatedObjects.h"
#import <objc/runtime.h>

@implementation NSObject (AssociatedObjects)

- (id)associatedObjectForKey:(const char *)key {
	return objc_getAssociatedObject(self, key);
}

- (void)setAssociatedObject:(id)object forKey:(const char *)key {
	objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_RETAIN);
}

@end
