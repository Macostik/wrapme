//
//  WLLogger.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "lelib.h"
#import "WLUser+Extended.h"
#import "WLAuthorization.h"

#define WL_LOG_DETAILED 0

#if WL_LOG_DETAILED

#define WLLog(LABEL,ACTION,OBJECT)\
NSString *str = [NSString stringWithFormat:@"%@ - %@",(LABEL), (ACTION)];\
NSLog(@"%@: %@", str, (OBJECT));\
int state = (int)[UIApplication sharedApplication].applicationState;\
[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@ >> (app state: %d) >> %@: %@", [WLUser combinedIdentifier], state, str, (OBJECT)]];

#else

#define WLLog(LABEL,ACTION,OBJECT)\
NSString *str = [NSString stringWithFormat:@"%@ - %@",(LABEL), (ACTION)];\
NSLog(@"%@", str);\
int state = (int)[UIApplication sharedApplication].applicationState;\
[[LELog sharedInstance] log:[NSString stringWithFormat:@"%@ >> (app state: %d) >> %@", [WLUser combinedIdentifier], state, str]];

#endif