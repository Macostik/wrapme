//
//  WLLogger.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "lelib.h"
#import "WLUser+Extended.h"
#import "WLAuthorization.h"

#define WL_LOG_DETAILED 1

#if WL_LOG_DETAILED
static inline void WLLog(NSString *label, NSString *action, id object) {
    id str = [NSString stringWithFormat:@"%@ - %@",label, action];
    CLS_LOG(@"%@: %@", str, object);
    WLUser *user = [WLUser currentUser];
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    if (user && authorization) {
        [[LELog sharedInstance] log:[NSString stringWithFormat:@"%@-%@ >> %@", user.identifier, authorization.deviceUID, str]];
    } else {
        [[LELog sharedInstance] log:str];
    }
    
}
#else
static inline void WLLog(NSString *label, NSString *action, id object) {
    id str = [NSString stringWithFormat:@"%@ - %@",label, action];
    CLS_LOG(@"%@", str);
    WLUser *user = [WLUser currentUser];
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    if (user && authorization) {
        [[LELog sharedInstance] log:[NSString stringWithFormat:@"%@-%@ >> %@", user.identifier, authorization.deviceUID, str]];
    } else {
        [[LELog sharedInstance] log:str];
    }
}
#endif
