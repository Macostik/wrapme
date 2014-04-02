//
//  WLProgressView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 02.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFURLConnectionOperation;

@interface WLProgressView : UIView

+ (void)showWithMessage:(NSString*)message image:(UIImage*)image operation:(AFURLConnectionOperation*)operation;

+ (void)showWithMessage:(NSString*)message operation:(AFURLConnectionOperation*)operation;

+ (void)dismiss;

@end
