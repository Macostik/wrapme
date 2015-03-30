//
//  WLUploadMessageRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLUploadMessageRequest : WLAPIRequest

@property (weak, nonatomic) WLMessage* message;

+ (instancetype)request:(WLMessage*)message;

@end
