//
//  PubNub+SharedInstance.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "PubNub+SharedInstance.h"

@implementation PubNub (SharedInstance)

+ (instancetype)sharedInstance {
    
    static id instance = nil;
    if (instance == nil) {
        NSString* origin, *publishKey, *subscribeKey, *secretKey;
        
        if ([WLAPIManager manager].environment.isProduction) {
            origin = @"pubsub.pubnub.com";
            publishKey = @"pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8";
            subscribeKey = @"sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe";
            secretKey = @"sec-c-NGE5NWU0NDAtZWMxYS00ZjQzLWJmMWMtZDU5MTE3NWE0YzE0";
        } else {
            origin = @"pubsub.pubnub.com";
            publishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
            subscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
            secretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";
        }
        
        PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:publishKey subscribeKey:subscribeKey];
        instance = [self clientWithConfiguration:configuration];
    }
    return instance;
}

@end
