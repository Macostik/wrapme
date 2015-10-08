//
//  WLExtensionsRequestMessage.h
//  meWrap
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionMessage.h"

@class WLExtensionRequest;
@class WLExtensionResponse;

@protocol WLExtensionRequestActions <NSObject>

@optional
- (void)postComment:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler;

- (void)postMessage:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler;

- (void)handleNotification:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler;

@end

@interface WLExtensionRequest : WLExtensionMessage

@property (strong, nonatomic) NSString *action;

+ (instancetype)requestWithAction:(NSString*)action userInfo:(NSDictionary*)userInfo;

@end
