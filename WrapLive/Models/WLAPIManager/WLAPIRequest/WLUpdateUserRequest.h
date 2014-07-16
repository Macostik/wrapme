//
//  WLUpdateUserRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadAPIRequest.h"

@interface WLUpdateUserRequest : WLUploadAPIRequest

@property (strong, nonatomic) WLUser* user;

+ (instancetype)request:(WLUser*)user;

@end
