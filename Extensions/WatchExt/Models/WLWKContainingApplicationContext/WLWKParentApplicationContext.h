//
//  WLWKContainingApplicationContext.h
//  meWrap
//
//  Created by Ravenpod on 6/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLWKParentApplicationContext : NSObject

+ (void)performAction:(SEL)action success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)performAction:(SEL)action parameters:(NSDictionary*)parameters success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWKParentApplicationContext (DefinedActions)

+ (void)postMessage:(NSString*)text wrap:(NSString*)wrapIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)postComment:(NSString*)text candy:(NSString*)candyIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

+ (void)handleNotification:(NSDictionary*)notification success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure;

@end
