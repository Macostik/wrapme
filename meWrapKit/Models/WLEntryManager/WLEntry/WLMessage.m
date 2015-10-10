//
//  WLMessage.m
//  meWrap
//
//  Created by Ravenpod on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessage.h"
#import "WLWrap.h"

@implementation WLMessage

@dynamic wrap;

@dynamic text;

- (WLAsset *)picture {
    return self.contributor.picture;
}

@end
