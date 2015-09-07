//
//  WLStoryboardTransition.h
//  meWrap
//
//  Created by Ravenpod on 1/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLStoryboardTransition : NSObject

@property (weak, nonatomic) IBOutlet UIViewController* sourceViewController;

@property (strong, nonatomic, readonly) UIViewController *destinationViewController;

@property (strong, nonatomic) IBInspectable NSString* destinationID;

@property (strong, nonatomic) IBInspectable NSString* storyboard;

@property (strong, nonatomic) IBInspectable NSString* sourceValue;

@property (strong, nonatomic) IBInspectable NSString* destinationValue;

@property (nonatomic) IBInspectable BOOL sourceIsDelegate;

@property (nonatomic) IBInspectable BOOL animated;

- (IBAction)push:(id)sender;

- (IBAction)pop:(id)sender;

- (IBAction)present:(id)sender;

@end
