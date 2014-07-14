//
//  WLPerson.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLContributor.h"

@class WLPicture;

@interface WLPerson : NSObject <WLContributor>

@property (strong, nonatomic) NSString *phone;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) WLUser *user;

@property (strong, nonatomic) WLPicture *picture;

- (BOOL)isEqualToPerson:(WLPerson*)person;

@end
