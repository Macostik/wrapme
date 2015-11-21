//
//  PubNub+SharedInstance.m
//  meWrap
//
//  Created by Ravenpod on 7/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "PubNub+SharedInstance.h"
#import "WLAPIEnvironment.h"

@implementation PubNub (SharedInstance)

static id instance = nil;

+ (instancetype)sharedInstance {
    if (instance == nil) {
        User *user = [User currentUser];
        if (!user) {
            return nil;
        }
        NSString *publishKey, *subscribeKey;
        
        if ([WLAPIEnvironment currentEnvironment].isProduction) {
            publishKey = @"pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8";
            subscribeKey = @"sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe";
        } else {
            publishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
            subscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
        }
        
        [PNLog enabled:NO];
        
        PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:publishKey subscribeKey:subscribeKey];
        configuration.uuid = user.identifier;
        instance = [self clientWithConfiguration:configuration];
    }
    return instance;
}

+ (void)setSharedInstance:(id)sharedInstance {
    instance = sharedInstance;
}

@end
