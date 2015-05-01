//
//  WLWKPostRow.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface WLWKEntryRow : NSObject

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *text;

@property (weak, nonatomic) WLEntry* entry;

@end
