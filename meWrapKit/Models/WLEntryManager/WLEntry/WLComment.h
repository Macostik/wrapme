//
//  WLComment.h
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContribution.h"

@class WLCandy;

@interface WLComment : WLContribution

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) WLCandy *candy;

@end
