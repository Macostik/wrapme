//
//  UIDevice+SystemVersion.h
//  moji
//
//  Created by Ravenpod on 03.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (SystemVersion)

- (BOOL)systemVersionEqualTo:(NSString*)version;

- (BOOL)systemVersionSince:(NSString*)version;

- (BOOL)systemVersionBefore:(NSString*)version;

@end

static NSString* relevantVersion = @"9";

static inline BOOL SystemVersionSinceRelevant(void) {
    static BOOL _value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _value = [[UIDevice currentDevice] systemVersionSince:relevantVersion];
    });
    return _value;
}

static inline void runSinceRelevantSystemVersion(void (^block) (void)) {
    if (SystemVersionSinceRelevant() && block) {
        block();
    }
}

static inline void runBeforeRelevantSystemVersion(void (^block) (void)) {
    if (!SystemVersionSinceRelevant() && block) {
        block();
    }
}

static inline void runBySystemVersion(void (^since) (void), void (^before) (void)) {
    if (SystemVersionSinceRelevant() && since) {
        since();
    } else if (before) {
        before();
    }
}
