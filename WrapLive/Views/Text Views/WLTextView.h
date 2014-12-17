//
//  WLTextView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIFont+CustomFonts.h"

@interface WLTextView : UITextView <WLFontCustomizing>

@property (strong, nonatomic) NSString *placeholder;

@end
