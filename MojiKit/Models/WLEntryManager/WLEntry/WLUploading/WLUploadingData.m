//
//  WLUploadingData.m
//  moji
//
//  Created by Ravenpod on 11/3/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadingData.h"
#import "WLUploading+Extended.h"
#import "AFHTTPRequestOperation.h"

@implementation WLUploadingData

- (void)setOperation:(AFHTTPRequestOperation *)operation {
    _operation = operation;
    self.progress = 0.0f;
    __weak typeof(self)weakSelf = self;
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = WLUploadingDataProgressPart * ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
        weakSelf.progress = progress;
        void (^progressBlock)(float progress) = weakSelf.progressBlock;
        if (progressBlock) progressBlock(progress);
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float progress = WLUploadingDataProgressPart + WLDownloadingDataProgressPart * ((float)totalBytesRead/(float)totalBytesExpectedToRead);
        weakSelf.progress =  progress;
        void (^progressBlock)(float progress) = weakSelf.progressBlock;
        if (progressBlock) progressBlock(progress);
    }];
}

- (void)setProgressBlock:(void (^)(float))progressBlock {
    _progressBlock = progressBlock;
}

@end
