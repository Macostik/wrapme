//
//  WLLogger.m
//  meWrap
//
//  Created by Ravenpod on 3/31/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLogger.h"
#import "lelib.h"
#import "WLUser+Extended.h"
#import "WLAuthorization.h"

@implementation WLLogger

+ (void)initialize {
    [LELog sharedInstance].token = @"e9e259b1-98e6-41b5-b530-d89d1f5af01d";
}

+ (void)systemLog:(NSString*)string {
    NSLog(@"%@", string);
}

+ (void)LE_log:(NSString*)string {
    [[LELog sharedInstance] log:string];
}

+ (void)log:(NSString *)label action:(NSString *)action object:(id)object {
    NSString *str = [NSString stringWithFormat:@"%@ - %@",label, action];
    [WLLogger systemLog:object ? [NSString stringWithFormat:@"%@: %@", str, object] : str];
    [WLLogger LE_log:[NSString stringWithFormat:@"%@ >> %@: %@", [WLUser combinedIdentifier], str, object]];
}

@end