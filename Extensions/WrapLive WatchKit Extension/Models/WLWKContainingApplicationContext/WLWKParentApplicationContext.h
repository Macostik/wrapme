//
//  WLWKContainingApplicationContext.h
//  moji
//
//  Created by Ravenpod on 6/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLWKParentApplicationContext : NSObject

+ (void)performAction:(NSString*)action success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)performAction:(NSString*)action parameters:(NSDictionary*)parameters success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWKParentApplicationContext (DefinedActions)

+ (void)requestAuthorization:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)postMessage:(NSString*)text wrap:(NSString*)wrapIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)postComment:(NSString*)text candy:(NSString*)candyIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

@end
