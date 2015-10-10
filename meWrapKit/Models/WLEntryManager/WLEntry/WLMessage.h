//
//  WLMessage.h
//  meWrap
//
//  Created by Ravenpod on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContribution.h"

@class WLWrap;

@interface WLMessage : WLContribution

@property (nonatomic, retain) WLWrap *wrap;

@property (nonatomic, retain) NSString * text;

@end
