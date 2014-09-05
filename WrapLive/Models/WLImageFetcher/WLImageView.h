//
//  WLImageView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLBlocks.h"

@class WLPicture;

@interface WLImageView : UIImageView

@property (nonatomic) NSString* url;

@property (nonatomic, weak) WLPicture *animatingPicture;

@property (nonatomic) NSString* placeholderName;

@property (strong, nonatomic) WLImageFetcherBlock success;

@property (strong, nonatomic) WLFailureBlock failure;

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure;

@end
