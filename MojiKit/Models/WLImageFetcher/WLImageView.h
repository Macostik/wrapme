//
//  WLImageView.h
//  moji
//
//  Created by Ravenpod on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLPicture;

typedef NS_ENUM(NSUInteger, WLImageViewState) {
    WLImageViewStateDefault,
    WLImageViewStateFailed,
    WLImageViewStateEmpty
};

@interface WLImageView : UIImageView

@property (nonatomic) NSString* url;

@property (nonatomic, weak) WLPicture *animatingPicture;

@property (strong, nonatomic) WLImageFetcherBlock success;

@property (strong, nonatomic) WLFailureBlock failure;

@property (nonatomic) WLImageViewState state;

- (void)setContentMode:(UIViewContentMode)contentMode forState:(WLImageViewState)state;

- (void)setImageName:(NSString *)imageName forState:(WLImageViewState)state;

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure;

@end
