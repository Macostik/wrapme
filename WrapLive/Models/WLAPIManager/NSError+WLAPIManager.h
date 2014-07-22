//
//  NSError+CustomErrors.h
//  Pressgram
//
//  Created by Sergey Maximenko on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAPIResponse.h"

static NSString* WLErrorDomain = @"com.wraplive.error";

typedef NS_ENUM(NSInteger, WLErrorCode) {
    WLErrorUnknown = -1,
    WLErrorDuplicatedUploading = 10,
    WLErrorInvalidAttributes = 20,
    WLErrorContentUnavaliable = 30,
    WLErrorMaxTimeLagExceeded = 40
};

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

@interface NSError (WLAPIManager)

@property (readonly, nonatomic) BOOL isDuplicatedUploading;

@property (readonly, nonatomic) BOOL isContentUnavaliable;

@property (readonly, nonatomic) BOOL isNetworkError;

+ (NSError*)errorWithDescription:(NSString*)description code:(NSInteger)code;
+ (NSError*)errorWithDescription:(NSString*)description;
- (void)show;
- (void)showWithTitle:(NSString*)title;
- (void)showWithTitle:(NSString*)title callback:(void (^)(void))callback;
- (void)showIgnoringNetworkError;

- (void)log;
- (void)log:(NSString*)label;

- (BOOL)isError:(WLErrorCode)code;

@end
