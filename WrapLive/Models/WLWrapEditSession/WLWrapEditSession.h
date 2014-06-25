//
//  WLWrapEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLTempWrap.h"


@interface WLWrapEditSession : NSObject

@property (strong, nonatomic) WLTempWrap *originalWrap;
@property (strong, nonatomic) WLTempWrap *changedWrap;

- (instancetype)initWithWrap:(WLWrap *)wrap;
- (BOOL)hasChanges;
- (void)applyChanges:(WLWrap *)wrap;
- (void)resetChanges:(WLWrap *)wrap;

@end
