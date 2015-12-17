//
//  WLProgressBar+WLContribution.m
//  meWrap
//
//  Created by Ravenpod on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar+WLContribution.h"

static CGFloat WLUploadingDataProgressPart = 0.5f;
static CGFloat WLDownloadingDataProgressPart = 0.5f;

@implementation WLProgressBar (WLContribution)

static inline float progressValue(float progress) {
    return WLDefaultProgress + (1.0f - WLDefaultProgress) * progress;
};

- (void)setOperation:(AFURLConnectionOperation *)operation {
    self.progress = WLDefaultProgress;
    __weak typeof(self)weakSelf = self;
    if ([Network sharedNetwork].reachable) {
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            float progress = WLUploadingDataProgressPart * ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
            [weakSelf setProgress:progressValue(progress) animated:YES];
        }];
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            float progress = WLUploadingDataProgressPart + WLDownloadingDataProgressPart * ((float)totalBytesRead/(float)totalBytesExpectedToRead);
            [weakSelf setProgress:progressValue(progress) animated:YES];
        }];
    }
}

@end
