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

static NSString* WLErrorResponseDataKey = @"com.wraplive.error.response.data";

typedef NS_ENUM(NSInteger, WLErrorCode) {
    WLErrorUnknown = -1,
    WLErrorDuplicatedUploading = 10,
    WLErrorInvalidAttributes = 20,
    WLErrorContentUnavaliable = 30,
    WLErrorNotFoundEntry = 40,
    WLErrorCredentialNotValid = 50,
    WLErrorUploadFileNotFound = 100,
    WLErrorEmailAlreadyConfirmed = 110,
};

@interface NSError (WLAPIManager)

@property (readonly, nonatomic) BOOL isDuplicatedUploading;

@property (readonly, nonatomic) BOOL isContentUnavaliable;

@property (readonly, nonatomic) BOOL isNetworkError;

+ (NSError*)errorWithResponse:(WLAPIResponse*)response;

+ (NSError*)errorWithDescription:(NSString*)description code:(NSInteger)code;
+ (NSError*)errorWithDescription:(NSString*)description;
- (void)show;
- (void)showIgnoringNetworkError;

+ (void)setShowingBlock:(WLFailureBlock)showingBlock;

- (NSString *)errorMessage;

- (BOOL)isError:(WLErrorCode)code;

@end

static inline NSError* WLError(NSString *description) {
    return [NSError errorWithDescription:description];
}
