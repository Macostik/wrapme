//
//  UIView+Extentions.m
//  
//  Created by Yuriy Granchenko on 28.05.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//
#import "UIView+Extentions.h"
#import "NSError+WLAPIManager.h"
#import "NSObject+AssociatedObjects.h"

@implementation UIView (Extentions)

- (UIView *)parentView {
	return [self associatedObjectForKey:"parentView"];
}

- (void)setParentView:(UIView *)parentView{
	[self setAssociatedObject:parentView forKey:"parentView"];
}

- (void)logSubviewsHierarchy {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#ifdef DEBUG
	WLLog(@"SubviewsHierarchy %@", [self performSelector:@selector(recursiveDescription)]);
#endif
}

- (id)findFirstResponder {
    if (self.isFirstResponder) {
        return self;
    }
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        if (firstResponder) {
            return firstResponder;
        }
    }
    return nil;
}

@end
