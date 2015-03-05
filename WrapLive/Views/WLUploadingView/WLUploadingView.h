//
//  WLUploadingView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/4/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLUploadingQueue;

@interface WLUploadingView : UIView

@property (weak, nonatomic) WLUploadingQueue* queue;

- (void)update;

@end
