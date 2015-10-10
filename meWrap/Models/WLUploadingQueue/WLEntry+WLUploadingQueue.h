//
//  WLEntry+WLUploadingQueue.h
//  meWrap
//
//  Created by Sergey Maximenko on 9/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

@interface WLEntry (WLUploadingQueue)

@end

typedef void (^WLContributionUpdatePreparingBlock)(WLContribution *contribution, WLContributionStatus status);

@interface WLContribution (WLUploadingQueue)

- (void)enqueueUpdate:(WLFailureBlock)failure;

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWrap (WLUploadingQueue)

- (void)uploadMessage:(NSString*)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLAsset *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLAsset *)picture;

- (void)uploadPictures:(NSArray *)pictures;

@end

@interface WLCandy (WLUploadingQueue)

- (id)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

- (void)editWithImage:(UIImage*)image;

@end
