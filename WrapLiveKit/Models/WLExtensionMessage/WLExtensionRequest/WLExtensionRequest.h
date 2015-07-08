//
//  WLExtensionsRequestMessage.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionMessage.h"

@interface WLExtensionRequest : WLExtensionMessage

@property (strong, nonatomic) NSString *action;

+ (instancetype)requestWithAction:(NSString*)action userInfo:(NSDictionary*)userInfo;

@end
