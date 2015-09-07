//
//  UIScreen+Diagonal.h
//  meWrap
//
//  Created by Ravenpod on 07.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ScreenDiagonal) {
	ScreenDiagonal3_5,
	ScreenDiagonal4
};

@interface UIScreen (Diagonal)

@property (nonatomic, readonly) ScreenDiagonal diagonal;

@end

static inline ScreenDiagonal WLMainScreenDiagonal() {
	return [UIScreen mainScreen].diagonal;
}

static inline BOOL WLMainScreenDiagonalIs4inch() {
	return ([UIScreen mainScreen].diagonal == ScreenDiagonal4);
}