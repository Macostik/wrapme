//
//  WLMessage.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLContribution.h"

@class WLWrap;

@interface WLMessage : WLContribution

@property (nonatomic, retain) WLWrap *wrap;

@property (nonatomic, retain) NSString * text;

@end
