//
//  WLValidation.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WLValidationStatus) {
    WLValidationStatusUndefined,
    WLValidationStatusInvalid,
    WLValidationStatusValid
};

@class WLValidation;

@protocol WLValidationDelegate <NSObject>

- (void)validationStatusChanged:(WLValidation*)validation;

@end

@interface WLValidation : NSObject

@property (nonatomic) WLValidationStatus status;

@property (strong, nonatomic) NSString* reason;

@property (nonatomic, weak) IBOutlet id <WLValidationDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView* inputView;

@property (weak, nonatomic) IBOutlet UIView* statusView;

- (WLValidationStatus)validate;

- (WLValidationStatus)defineCurrentStatus:(UIView*)inputView;

@end
