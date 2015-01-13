//
//  WLGradientDrawer.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLGradientDrawer : NSObject

+ (UIImage*)imageWithSize:(CGFloat)size color:(UIColor*)color mode:(UIViewContentMode)mode;

@end
