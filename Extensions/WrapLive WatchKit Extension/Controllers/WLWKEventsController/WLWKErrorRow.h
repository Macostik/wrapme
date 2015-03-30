//
//  WLErrorRow.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/30/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface WLWKErrorRow : NSObject

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *errorDescriptionLabel;

- (void)setError:(NSError*)error;

@end
