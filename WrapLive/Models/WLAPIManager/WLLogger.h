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

#define WLLog(LABEL,ACTION,OBJECT)\
NSString *str = [NSString stringWithFormat:@"%@ - %@",(LABEL), (ACTION)];\
CLS_LOG(@"%@: %@", str, (OBJECT));\
[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@ >> %@: %@", [WLUser combinedIdentifier], str, (OBJECT)]];

#else

#define WLLog(LABEL,ACTION,OBJECT)\
NSString *str = [NSString stringWithFormat:@"%@ - %@",(LABEL), (ACTION)];\
CLS_LOG(@"%@", str);\
[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@ >> %@", [WLUser combinedIdentifier], str]];

#endif