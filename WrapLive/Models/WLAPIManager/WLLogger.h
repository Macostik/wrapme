//
//  WLLogger.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

static const BOOL detailedLog = YES;

static inline void WLLog(NSString* label, NSString* action, id object) {
#if DEBUG
    if (detailedLog && object) {
        NSLog(@"%@ - %@: %@", label, action, object);
    } else {
        NSLog(@"%@ - %@", label, action);
    }
#endif
}
