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

- (id)associatedObjectForKey:(NSString*)key {
	return objc_getAssociatedObject(self, (__bridge const void *)(key));
}

- (void)setAssociatedObject:(id)object forKey:(NSString*)key {
	objc_setAssociatedObject(self, (__bridge const void *)(key), object, OBJC_ASSOCIATION_RETAIN);
}

@end
