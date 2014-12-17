//
//  WLConfirmView.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefinedBlocks.h"

@interface WLConfirmView : UIView

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

- (void)confirmationSuccess:(WLBlock)succes failure:(WLBlock)failure;

@end
