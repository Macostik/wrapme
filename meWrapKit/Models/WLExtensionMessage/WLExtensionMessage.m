//
//  WLExtensionMessage.m
//  meWrap
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionMessage.h"

@implementation WLExtensionMessage

+ (NSSet *)archivableProperties {
    return [NSSet setWithObjects:@"userInfo", nil];
}

+ (NSString*)serializationKey {
    return nil;
}

+ (instancetype)deserialize:(NSDictionary*)dictionary {
    return [self unarchive:dictionary[[self serializationKey]]];
}

- (NSDictionary*)serialize {
    return @{[[self class] serializationKey]:[self archive]};
}

@end
