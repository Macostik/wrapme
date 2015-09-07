//
//  WLProfileEditSession.h
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"

@interface WLProfileEditSession : WLEditSession

- (id)initWithUser:(WLEntry *)entry;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSString *email;

@property (strong, nonatomic) NSString *url;

- (BOOL)hasChangedName;

- (BOOL)hasChangedEmail;

- (BOOL)hasChangedUrl;

@end
