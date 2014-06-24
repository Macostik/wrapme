//
//  WLTempWrap.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLPicture;
@class WLWrap;
@class WLUser;

@interface WLTempWrap : NSObject

@property (weak, nonatomic) WLWrap *wrap;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) WLPicture *picture;
@property (strong, nonatomic) NSOrderedSet *contributors;
@property (strong, nonatomic) NSArray *invitees;

@property (strong, nonatomic) WLUser *contributor;

- (instancetype)initWithWrap:(WLWrap *)wrap;

@end
