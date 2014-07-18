//
//  WLImageView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLBlocks.h"

@interface WLImageView : UIImageView

@property (nonatomic) NSString* url;

@property (nonatomic) NSString* placeholderName;

- (void)setUrl:(NSString *)url completion:(WLImageFetcherBlock)completion;

@property (strong, nonatomic) WLImageFetcherBlock completionBlock;

@end
