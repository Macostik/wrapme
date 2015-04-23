//
//  WLReplyPresetsController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WLWKReplyPresetsController : WKInterfaceController

- (NSString*)presetsPropertyListName;

- (void)handlePreset:(NSString*)preset success:(WLBlock)success failure:(WLFailureBlock)failure;

@end
