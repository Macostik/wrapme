//
//  StreamViewDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamView.h"

@interface StreamViewDataSource : NSObject <StreamViewDelegate>

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) id <WLBaseOrderedCollection> items;

@property (strong, nonatomic) StreamMetrics *metrics;

@property (strong, nonatomic) IBInspectable NSString *itemIdentifier;

@property (nonatomic) IBInspectable CGFloat itemSize;

- (void)reload;

@end
