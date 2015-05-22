//
//  WLDownloadingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLDownloadingView : UIView

+ (void)downloadAndEditCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

+ (instancetype)downloadingViewForCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

+ (instancetype)downloadingView:(UIView *)view forCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

@end
