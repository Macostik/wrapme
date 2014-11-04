//
//  WLProgressBar+WLContribution.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar+WLContribution.h"
#import <AFNetworking/AFURLConnectionOperation.h>
#import "WLInternetConnectionBroadcaster.h"
#import "WLContribution+Extended.h"
#import "WLUploading+Extended.h"
#import "NSObject+AssociatedObjects.h"

@implementation WLProgressBar (WLContribution)

- (void)setContribution:(WLContribution *)contribution {
    switch (contribution.status) {
        case WLContributionStatusReady:
        case WLContributionStatusInProgress: {
            self.hidden = NO;
            __weak typeof(self)weakSelf = self;
            [contribution.uploading.data setProgressBlock:^(float progress) {
                [weakSelf setProgress:WLDefaultProgress + (1.0f - WLDefaultProgress) * progress animated:YES];
            }];
        } break;
        case WLContributionStatusUploaded:
            self.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
    self.progress = WLDefaultProgress;
    __weak typeof(self)weakSelf = self;
    if ([WLInternetConnectionBroadcaster broadcaster].reachable) {
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            float progress = 0.5f * ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
            [weakSelf setProgress:WLDefaultProgress + (1.0f - WLDefaultProgress) * progress animated:YES];
        }];
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            float progress = 0.5f + 0.5f * ((float)totalBytesRead/(float)totalBytesExpectedToRead);
            [weakSelf setProgress:WLDefaultProgress + (1.0f - WLDefaultProgress) * progress animated:YES];
        }];
    }
}

@end
