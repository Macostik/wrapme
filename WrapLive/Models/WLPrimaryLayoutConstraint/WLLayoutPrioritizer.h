//
//  WLPrimaryLayoutConstraint.h
//  WrapLive
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLLayoutPrioritizer : NSObject

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *defaultConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *alternativeConstraints;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *parentViews;

@property (assign, nonatomic) BOOL defaultState;

- (void)setDefaultState:(BOOL)state animated:(BOOL)animated;

@end
