//
//  WLContributorsViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBlocks.h"

@class WLWrap;
@class WLTempWrap;

typedef void (^WLContactsBlock) (NSMutableOrderedSet *contributors, NSArray *invitees);

@interface WLContributorsViewController : UIViewController

@property (strong, nonatomic) NSOrderedSet *contributors;
@property (strong, nonatomic) NSArray *invitees;
@property (strong, nonatomic) WLContactsBlock contactsBlock;

@end
