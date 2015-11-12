//
//  WLImageView.h
//  meWrap
//
//  Created by Ravenpod on 7/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefinedBlocks.h"

@class Asset;

@interface WLImageView : UIImageView

@property (strong, nonatomic) IBOutlet UILabel *defaultIconView;

@property (nonatomic) IBInspectable CGFloat defaultIconSize;

@property (strong, nonatomic) IBInspectable NSString *defaultIconText;

@property (strong, nonatomic) IBInspectable UIColor *defaultIconColor;

@property (strong, nonatomic) IBInspectable UIColor *defaultBackgroundColor;

@property (nonatomic) NSString* url;

@property (strong, nonatomic) WLImageFetcherBlock success;

@property (strong, nonatomic) WLFailureBlock failure;

- (void)setUrl:(NSString *)url success:(WLImageFetcherBlock)success failure:(WLFailureBlock)failure;

@end
