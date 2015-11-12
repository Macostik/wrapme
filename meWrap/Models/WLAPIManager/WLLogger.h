//
//  WLLogger.h
//  meWrap
//
//  Created by Ravenpod on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LogEntries/LELog.h>

__attribute__((constructor))
static void WLInitializeLELog (void) {
    [LELog sharedInstance].token = @"e9e259b1-98e6-41b5-b530-d89d1f5af01d";
}

#ifdef DEBUG

#define WLLog(format, ...)\
NSLog(format, ##__VA_ARGS__);\

#else

#define WLLog(format, ...)\
[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@-%@ >> %@", [User currentUser].identifier, [Authorization currentAuthorization].deviceUID, [NSString stringWithFormat:format, ##__VA_ARGS__]]];

#endif

