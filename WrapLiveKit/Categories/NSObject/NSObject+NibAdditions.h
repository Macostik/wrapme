//
//  NSObject+PGAdditions.h
//  moji
//
//  Created by Andrey Ivanov on 21.05.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NibAdditions)

+ (id)loadFromNib;
+ (id)loadFromNibNamed:(NSString *)nibName;
+ (id)loadFromNibNamed:(NSString *)nibName ownedBy:(id)owner;
+ (id)loadFromNib:(UINib *)nib ownedBy:(id)owner;

+ (UINib *)nib;
+ (UINib *)nibNamed:(NSString*)nibName;

@end
