//
//  WLLogger.h
//  meWrap
//
//  Created by Ravenpod on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLLogger : NSObject

+ (void)systemLog:(NSString*)string;

+ (void)LE_log:(NSString*)string;

+ (void)log:(NSString*)label action:(NSString*)action object:(id)object;

@end

#define WL_LOG_DETAILED 1

#if WL_LOG_DETAILED

#define WLLog(LABEL,ACTION,OBJECT)\
[WLLogger log:(LABEL) action:(ACTION) object:(OBJECT)];

#else

#define WLLog(LABEL,ACTION,OBJECT)\
[WLLogger log:(LABEL) action:(ACTION) object:nil];

#endif
