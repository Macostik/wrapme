//
//  NSObject+PGAdditions.m
//  meWrap
//
//  Created by Andrey Ivanov on 21.05.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "NSObject+NibAdditions.h"

@implementation NSObject (NibAdditions)

+ (id)loadFromNib {
	return [self loadFromNib:[self nib] ownedBy:nil];
}

+ (id)loadFromNibNamed:(NSString *)nibName {
	return [self loadFromNibNamed:nibName ownedBy:nil];
}

+ (id)loadFromNibNamed:(NSString *)nibName ownedBy:(id)owner {
	return [self loadFromNib:[self nibNamed:nibName] ownedBy:owner];
}

+ (id)loadFromNib:(UINib *)nib ownedBy:(id)owner {
	NSArray *bundleObjects = [nib instantiateWithOwner:owner options:nil];
	for (id obj in bundleObjects) {
		if ([obj isKindOfClass:[self class]]) {
			return obj;
		}
	}
	return nil;
}

+ (UINib *)nib {
	return [self nibNamed:NSStringFromClass(self.class)];
}

+ (UINib *)nibNamed:(NSString *)nibName {
	return [UINib nibWithNibName:nibName bundle:nil];
}

@end
