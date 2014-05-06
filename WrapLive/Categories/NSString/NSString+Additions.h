//
//  NSString+Hash.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/3/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* GUID();
BOOL NSStringEqual(NSString* string1, NSString* string2);

@interface NSString (Additions)

- (BOOL)isValidEmail;

- (NSString*)trim;

@end
