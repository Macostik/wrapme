//
//  WLRemoteObjectHandler.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBroadcaster.h"

@class WLRemoteObjectHandler;

@protocol WLObjectReceiver

@optional

- (void)broadcaster:(WLRemoteObjectHandler *)broadcaster didReceiveRemoteObject:(id)object;

@end

@interface WLRemoteObjectHandler : NSObject

+ (void)presentViewControllerByUrlExtension:(NSURL *)url;

@end
