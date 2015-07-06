//
//  WLWrapContributorsRequest.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@interface WLWrapContributorsRequest : WLAPIRequest

@property (weak, nonatomic) WLWrap *wrap;

+ (instancetype)request:(WLWrap*)wrap;

@end
