//
//  WLAddressBookPhoneNumber.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLPicture;
@class WLUser;
@class WLAddressBookRecord;

static NSInteger WLAddressBookPhoneNumberMinimumLength = 6;

@interface WLAddressBookPhoneNumber : NSObject

@property (weak, nonatomic) WLAddressBookRecord* record;

@property (strong, nonatomic) NSString *phone;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) WLUser *user;

@property (strong, nonatomic) WLPicture *picture;

@property (nonatomic) BOOL activated;

- (BOOL)isEqualToPerson:(WLAddressBookPhoneNumber*)person;
- (NSString *)priorityName;
- (WLPicture *)priorityPicture;

@end
