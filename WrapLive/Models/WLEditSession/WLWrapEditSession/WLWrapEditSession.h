//
//  WLWrapEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"
#import "WLWrap.h"

@interface WLWrapEditSession : WLEditSession

@property (weak, nonatomic) WLWrap* entry;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSString *url;

@property (strong, nonatomic) NSMutableOrderedSet *contributors;

@property (strong, nonatomic) NSMutableArray *invitees;

@end
