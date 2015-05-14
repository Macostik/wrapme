//
//  WLDownloadingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLDownloadingView : UIView

+ (instancetype)downloadingView:(UIView *)view forCandy:(WLCandy *)candy success:(WLBlock)success failure:(WLFailureBlock)failure;
- (instancetype)downloadingView:(UIView *)view forEntry:(WLCandy *)candy success:(WLBlock)success failure:(WLFailureBlock)failure;

@end
