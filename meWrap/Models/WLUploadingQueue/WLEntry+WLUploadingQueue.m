//
//  WLEntry+WLUploadingQueue.m
//  meWrap
//
//  Created by Sergey Maximenko on 9/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+WLUploadingQueue.h"
#import "WLUploadingQueue.h"
#import "WLLocalization.h"
#import "WLUploading+Extended.h"
#import "WLEditPicture.h"

@implementation WLEntry (WLUploadingQueue)

@end

@implementation WLContribution (WLUploadingQueue)

- (void)enqueueUpdate:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
        switch (status) {
            case WLContributionStatusReady: break;
            case WLContributionStatusFinished: {
                [weakSelf notifyOnUpdate];
                [WLUploadingQueue upload:[WLUploading uploading:weakSelf type:WLEventUpdate] success:nil failure:nil];
            } break;
            default:
                break;
        }
    } failure:failure];
}

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure {
    WLContributionStatus status = [self statusOfAnyUploadingType];
    if (status == WLContributionStatusInProgress) {
        if (failure) failure(WLError(WLLS(@"photo_is_uploading")));
    } else {
        if (success) success(self, status);
    }
}

@end

@implementation WLWrap (WLUploadingQueue)

- (void)uploadMessage:(NSString *)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure {
    __weak WLMessage* message = [WLMessage contribution];
    message.contributor = [WLUser currentUser];
    message.wrap = self;
    message.text = text;
    [message notifyOnAddition];
    [WLUploadingQueue upload:[WLUploading uploading:message] success:success failure:failure];
}

- (void)uploadPicture:(WLEditPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:picture.type wrap:self];
    candy.picture = [picture uploadablePicture:YES];
    if (picture.comment.nonempty) {
        [candy addCommentsObject:[WLComment comment:picture.comment]];
    }
    [self addCandiesObject:candy];
    [self touch];
    [candy notifyOnAddition];
    [WLUploadingQueue upload:[WLUploading uploading:candy] success:success failure:failure];
}

- (void)uploadPicture:(WLAsset *)picture {
    [self uploadPicture:picture success:^(WLCandy *candy) { } failure:^(NSError *error) { }];
}

- (void)uploadPictures:(NSArray *)pictures {
    __weak typeof(self)weakSelf = self;
    for (WLAsset *picture in pictures) {
        runUnaryQueuedOperation(@"wl_upload_candies_queue", ^(WLOperation *operation) {
            [weakSelf uploadPicture:picture];
            run_after(0.6f, ^{
                [operation finish];
            });
        });
    }
}

@end

@implementation WLCandy (WLUploadingQueue)

- (id)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    WLUploading* uploading = [WLUploading uploading:comment];
    [self addComment:comment];
    run_after(0.3f,^{
        [WLUploadingQueue upload:uploading success:success failure:failure];
    });
    return comment;
}

- (void)editWithImage:(UIImage*)image {
    if (self.valid) {
        __weak typeof(self)weakSelf = self;
        __block WLEditPicture *picture = [WLEditPicture picture:image completion:^(id object) {
            [weakSelf setEditedPictureIfNeeded:[picture uploadablePicture:NO]];
            [weakSelf enqueueUpdate:^(NSError *error) {
                [error show];
            }];
        }];
    }
}

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure {
    WLContributionStatus status = [self statusOfAnyUploadingType];
    switch (status) {
        case WLContributionStatusInProgress:
            if (failure) failure(WLError([self messageAppearanceByCandyType:@"video_is_uploading" and:@"photo_is_uploading"]));
            break;
        case WLContributionStatusFinished:
            if ([self.identifier isEqualToString:self.uploadIdentifier]) {
                if (failure) failure([NSError errorWithDescription:WLLS(@"publishing_in_progress")]);
            } else {
                if (success) success(self, status);
            }
            break;
        default:
            if (success) success(self, status);
            break;
    }
}

@end