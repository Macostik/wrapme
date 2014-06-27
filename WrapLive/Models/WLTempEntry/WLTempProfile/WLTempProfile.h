//
//  WLTempProfile.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTempEntry.h"

@class WLUser;
@class WLPicture;

@interface WLTempProfile : WLTempEntry

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) WLPicture *picture;


@end
