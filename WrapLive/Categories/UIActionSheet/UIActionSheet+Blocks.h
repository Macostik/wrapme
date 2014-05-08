//
//  UIActionSheet+Blocks.h
//  WrapLive
//
//  Created by Sergey Maximenko on 06.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLActionSheetCompletion)(NSUInteger index);

@interface UIActionSheet (Blocks)

+ (void)showWithTitle:(NSString *)title cancel:(NSString*)cancel destructive:(NSString*)destructive buttons:(NSArray *)buttons completion:(WLActionSheetCompletion)completion;

+ (void)showWithTitle:(NSString *)title destructive:(NSString*)destructive completion:(WLActionSheetCompletion)completion;

+ (void)showWithTitle:(NSString *)title cancel:(NSString*)cancel destructive:(NSString*)destructive completion:(WLActionSheetCompletion)completion;

+ (void)showWithCondition:(NSString *)title completion:(WLActionSheetCompletion)completion;

@end
