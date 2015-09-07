//
//  WLUploadingData.h
//  meWrap
//
//  Created by Ravenpod on 11/3/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLUploading;
@class AFHTTPRequestOperation;

static CGFloat WLUploadingDataProgressPart = 0.5f;
static CGFloat WLDownloadingDataProgressPart = 0.5f;

@interface WLUploadingData : NSObject

@property (weak, nonatomic) WLUploading* uploading;

@property (weak, nonatomic) AFHTTPRequestOperation* operation;

@property (nonatomic) float progress;

@property (strong, nonatomic) void (^progressBlock)(float progress);

@end
