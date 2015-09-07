//
//  WLExtensionMessage.h
//  meWrap
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"

@interface WLExtensionMessage : WLArchivingObject

@property (strong, nonatomic) NSDictionary *userInfo;

+ (instancetype)deserialize:(NSDictionary*)dictionary;

- (NSDictionary*)serialize;

@end
