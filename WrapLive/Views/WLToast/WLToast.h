//
//  WLToast.h
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLToast : UIView

+ (instancetype)toast;

+ (void)showWithMessage:(NSString*)message;
- (void)showWithMessage:(NSString*)message;

@property (nonatomic) NSString* message;

@end
