//
//  NSError+CustomErrors.h
//  Pressgram
//
//  Created by Sergey Maximenko on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* WLErrorDomain = @"com.wraplive.error";

typedef NS_ENUM(NSInteger, PGErrorCode) {
    kWLErrorCodeUnknown = 0,
};

static const BOOL detailedLog = NO;

static inline void WLLog(NSString* label, id object) {
#if DEBUG
    if (detailedLog) {
        NSLog(@"%@: %@", label, object);
    } else {
        NSLog(@"%@", label);
    }
#endif
}

@interface NSError (WLAPIManager)

+ (NSError*)errorWithDescription:(NSString*)description code:(NSInteger)code;
+ (NSError*)errorWithDescription:(NSString*)description;
- (void)show;
- (void)showWithTitle:(NSString*)title;
- (void)showWithTitle:(NSString*)title callback:(void (^)(void))callback;
- (void)showIgnoringNetworkError;

- (BOOL)isNetworkError;

- (void)log;
- (void)log:(NSString*)label;

@end
