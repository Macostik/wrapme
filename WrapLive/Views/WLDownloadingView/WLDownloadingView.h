//
//  WLDownloadingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLDownloadingView : UIView

+ (instancetype)downloadCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

- (instancetype)downloadCandy:(WLCandy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

@end
