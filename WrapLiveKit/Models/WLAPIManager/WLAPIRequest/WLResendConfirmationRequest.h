//
//  WLResendConfirmationRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLResendConfirmationRequest : WLAPIRequest

@property (strong, nonatomic) NSString *email;

@end
