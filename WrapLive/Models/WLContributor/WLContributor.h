//
//  WLContributor.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 7/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPicture.h"

@protocol WLContributor

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *phone;
@property (readonly, nonatomic) WLPicture *picture;

@end