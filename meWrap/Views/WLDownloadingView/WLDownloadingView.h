//
//  WLDownloadingView.h
//  meWrap
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLDownloadingView : UIView

+ (instancetype)downloadCandy:(Candy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

- (instancetype)downloadCandy:(Candy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure;

@end
