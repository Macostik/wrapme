//
//  WLLogger.h
//  meWrap
//
//  Created by Ravenpod on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LELog.h"
#import "WLUser.h"
#import "WLAuthorization.h"

__attribute__((constructor))
static void WLInitializeLELog (void) {
    [LELog sharedInstance].token = @"e9e259b1-98e6-41b5-b530-d89d1f5af01d";
}

#define WLLog(format, ...)\
NSLog(format, ##__VA_ARGS__);\

//#ifdef DEBUG
//
//#define WLLog(format, ...)\
//NSLog(format, ##__VA_ARGS__);\
//
//#else
//
//#define WLLog(format, ...)\
//[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@-%@ >> %@", [WLUser currentUser].identifier, [WLAuthorization currentAuthorization].deviceUID, [NSString stringWithFormat:format, ##__VA_ARGS__]]];
//
//#endif
