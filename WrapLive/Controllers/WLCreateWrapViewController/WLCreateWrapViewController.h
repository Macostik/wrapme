//
//  WLCreateWrapViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLCreateWrapViewController : WLBaseViewController <UITextFieldDelegate>

@property (strong, nonatomic) WLBlock cancelHandler;

@property (strong, nonatomic) WLWrapBlock createHandler;

@end


