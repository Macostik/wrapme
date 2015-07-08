//
//  WLExtensionMessage.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"

@interface WLExtensionMessage : WLArchivingObject

@property (strong, nonatomic) NSDictionary *userInfo;

+ (instancetype)deserialize:(NSDictionary*)dictionary;

- (NSDictionary*)serialize;

@end
