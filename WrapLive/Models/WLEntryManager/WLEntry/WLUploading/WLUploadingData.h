//
//  WLUploadingData.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/3/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

@interface WLUploadingData : NSObject

@property (weak, nonatomic) AFHTTPRequestOperation* operation;

@property (nonatomic) float progress;

@property (strong, nonatomic) UIView* progressView;

@property (strong, nonatomic) void (^progressBlock)(float progress);

@end
