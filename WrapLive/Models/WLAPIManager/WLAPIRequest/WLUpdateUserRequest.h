//
//  WLUpdateUserRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadAPIRequest.h"

@interface WLUpdateUserRequest : WLUploadAPIRequest

@property (weak, nonatomic) WLUser* user;
@property (strong, nonatomic) NSString *email;

+ (instancetype)request:(WLUser*)user;

@end
