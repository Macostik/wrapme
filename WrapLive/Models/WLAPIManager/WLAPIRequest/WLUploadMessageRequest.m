//
//  WLUploadMessageRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadMessageRequest.h"
#import "WLWrapBroadcaster.h"

@implementation WLUploadMessageRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(WLMessage *)message {
    WLUploadMessageRequest* request = [WLUploadMessageRequest request];
    request.message = message;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/chats", self.message.wrap.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLMessage* message = self.message;
    [parameters trySetObject:message.text forKey:@"message"];
    [parameters trySetObject:message.uploadIdentifier forKey:@"upload_uid"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLMessage* message = self.message;
    [message API_setup:[response.data dictionaryForKey:@"chat"]];
    [message.wrap touch:message.createdAt];
    [message broadcastChange];
    return message;
}

@end
