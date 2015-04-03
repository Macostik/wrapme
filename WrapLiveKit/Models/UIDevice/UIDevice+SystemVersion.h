//
//  UIDevice+SystemVersion.h
//  Pressgram
//
//  Created by Sergey Maximenko on 03.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (SystemVersion)

- (BOOL)systemVersionEqualTo:(NSString*)version;
- (BOOL)systemVersionGreaterThan:(NSString*)version;
- (BOOL)systemVersionGreaterThanOrEqualTo:(NSString*)version;
- (BOOL)systemVersionLessThan:(NSString*)version;
- (BOOL)systemVersionLessThanOrEqualTo:(NSString*)version;

@end

static inline BOOL SystemVersionGreaterThanOrEqualTo8(void) {
    static BOOL _value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _value = [[UIDevice currentDevice] systemVersionGreaterThanOrEqualTo:@"8"];
    });
    return _value;
}

static inline void runOnlyIfSystemVersionGreaterThanOrEqualTo8(void (^greaterThanOrEqualTo8Block) (void)) {
    if (SystemVersionGreaterThanOrEqualTo8() && greaterThanOrEqualTo8Block) {
        greaterThanOrEqualTo8Block();
    }
}

static inline void runOnlyIfSystemVersionLessThan8(void (^lessThan8Block) (void)) {
    if (!SystemVersionGreaterThanOrEqualTo8() && lessThan8Block) {
        lessThan8Block();
    }
}

static inline void runBySystemVersion(void (^greaterThanOrEqualTo8Block) (void), void (^lessThan8Block) (void)) {
    if (SystemVersionGreaterThanOrEqualTo8() && greaterThanOrEqualTo8Block) {
        greaterThanOrEqualTo8Block();
    } else if (lessThan8Block) {
        lessThan8Block();
    }
}
