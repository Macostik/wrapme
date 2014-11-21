//
//  WLLogger.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>

#define WL_LOG_DETAILED 0

#if WL_LOG_DETAILED
#define WLLog(LABEL,ACTION,OBJECT) CLS_LOG(@"%@ - %@: %@", (LABEL), (ACTION), (OBJECT))
#else
#define WLLog(LABEL,ACTION,OBJECT) CLS_LOG(@"%@ - %@", (LABEL), (ACTION))
#endif
