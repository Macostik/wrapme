//
//  WLEntry+WLUploadingQueue.h
//  meWrap
//
//  Created by Sergey Maximenko on 9/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

@interface Entry (WLUploadingQueue)

@end

typedef void (^WLContributionUpdatePreparingBlock)(Contribution *contribution, WLContributionStatus status);

@interface Contribution (WLUploadingQueue)

- (void)enqueueUpdate:(WLFailureBlock)failure;

- (void)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure;

@end

@interface Wrap (WLUploadingQueue)

- (void)uploadMessage:(NSString*)text success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(Asset *)picture success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(Asset *)picture;

- (void)uploadPictures:(NSArray *)pictures;

@end

@interface Candy (WLUploadingQueue)

- (id)uploadComment:(NSString *)text success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)editWithImage:(UIImage*)image;

@end
