//
//  WLEntry+WLUploadingQueue.m
//  meWrap
//
//  Created by Sergey Maximenko on 9/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+WLUploadingQueue.h"
#import "WLUploadingQueue.h"
#import "WLUploading+Extended.h"

@implementation Entry (WLUploadingQueue)

@end

@implementation Contribution (WLUploadingQueue)

- (void)enqueueUpdate:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self prepareForUpdate:^(Contribution *contribution, WLContributionStatus status) {
        switch (status) {
            case WLContributionStatusReady: break;
            case WLContributionStatusFinished: {
                [weakSelf notifyOnUpdate];
                [WLUploadingQueue upload:[Uploading uploading:weakSelf type:WLEventUpdate] success:nil failure:nil];
            } break;
            default:
                break;
        }
    } failure:failure];
}

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure {
    WLContributionStatus status = [self statusOfAnyUploadingType];
    if (status == WLContributionStatusInProgress) {
        if (failure) failure(WLError(@"photo_is_uploading".ls));
    } else {
        if (success) success(self, status);
    }
}

@end

@implementation Wrap (WLUploadingQueue)

- (void)uploadMessage:(NSString *)text success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak Message *message = [Message contribution];
    message.contributor = [User currentUser];
    message.wrap = self;
    message.text = text;
    [message notifyOnAddition];
    [WLUploadingQueue upload:[Uploading uploading:message] success:success failure:failure];
}

- (void)uploadPicture:(MutableAsset *)picture success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    Candy *candy = [Candy candy:picture.type];
    candy.wrap = self;
    candy.picture = [picture uploadablePicture:YES];
    if (picture.comment.nonempty) {
        [[candy mutableComments] addObject:[Comment comment:picture.comment]];
    }
    [[self mutableCandies] addObject:candy];
    [self touch];
    [candy notifyOnAddition];
    [WLUploadingQueue upload:[Uploading uploading:candy] success:success failure:failure];
}

- (void)uploadPicture:(Asset *)picture {
    [self uploadPicture:picture success:^(Candy *candy) { } failure:^(NSError *error) { }];
}

- (void)uploadPictures:(NSArray *)pictures {
    __weak typeof(self)weakSelf = self;
    for (Asset *picture in pictures) {
        runUnaryQueuedOperation(@"wl_upload_candies_queue", ^(WLOperation *operation) {
            [weakSelf uploadPicture:picture];
            run_after(0.6f, ^{
                [operation finish];
            });
        });
    }
}

@end

@implementation Candy (WLUploadingQueue)

- (id)uploadComment:(NSString *)text success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    Comment *comment = [Comment comment:text];
    Uploading *uploading = [Uploading uploading:comment];
    self.commentCount++;
    [[self mutableComments] addObject:comment];
    [self touch];
    [comment notifyOnAddition];
    run_after(0.3f,^{
        [WLUploadingQueue upload:uploading success:success failure:failure];
    });
    return comment;
}

- (void)editWithImage:(UIImage*)image {
    if (self.valid) {
        MutableAsset *picture = [[MutableAsset alloc] init];
        [picture setImage:image];
        [self setEditedPictureIfNeeded:[picture uploadablePicture:NO]];
        [self enqueueUpdate:^(NSError *error) {
            [error show];
        }];
    }
}

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure {
    WLContributionStatus status = [self statusOfAnyUploadingType];
    switch (status) {
        case WLContributionStatusInProgress:
            if (failure) failure(WLError((self.isVideo ? @"video_is_uploading" : @"photo_is_uploading").ls));
            break;
        case WLContributionStatusFinished:
            if ([self.identifier isEqualToString:self.uploadIdentifier]) {
                if (failure) failure([NSError errorWithDescription:@"publishing_in_progress".ls]);
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