//
//  WLProgressBar+WLContribution.m
//  meWrap
//
//  Created by Ravenpod on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar+WLContribution.h"
#import "NSObject+AssociatedObjects.h"

@implementation WLProgressBar (WLContribution)

static inline float progressValue(float progress) {
    return WLDefaultProgress + (1.0f - WLDefaultProgress) * progress;
};

- (void)setContribution:(WLContribution *)contribution {
    if (!contribution) {
        self.hidden = YES;
        return;
    }
    switch (contribution.status) {
        case WLContributionStatusReady:
        case WLContributionStatusInProgress: {
            self.hidden = NO;
            __weak typeof(self)weakSelf = self;
            void (^progressBlock)(float, BOOL) = ^ (float progress, BOOL animated) {
                progress = progressValue(progress);
                [weakSelf setProgress:progress animated:animated];
                if (progress == 1) {
                    run_after(1.0f, ^{
                        weakSelf.hidden = YES;
                    });
                }
            };
            progressBlock(contribution.uploading.data.progress, NO);
            [contribution.uploading.data setProgressBlock:^(float progress) {
                progressBlock(progress, YES);
            }];
        } break;
        case WLContributionStatusFinished:
            self.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
    self.progress = WLDefaultProgress;
    __weak typeof(self)weakSelf = self;
    if ([WLNetwork network].reachable) {
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
