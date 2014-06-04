//
//  WLInviteViewContraller.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 6/3/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLPhoneNumbersBlock) (NSArray *contacts);

@interface WLInviteViewController : UIViewController

@property (strong, nonatomic) WLPhoneNumbersBlock phoneNumberBlock;

@end