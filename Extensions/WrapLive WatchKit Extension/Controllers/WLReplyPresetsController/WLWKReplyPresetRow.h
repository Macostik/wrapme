//
//  WLWKReplyPresetRow.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface WLWKReplyPresetRow : NSObject

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *text;

- (void)setPreset:(NSString*)preset;

@end
