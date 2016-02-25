//
//  ImageEditor.h
//  meWrap
//
//  Created by Sergey Maximenko on 10/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageEditor : NSObject

+ (void)editImage:(UIImage* __nonnull)image completion:(void (^ __nonnull) (UIImage * __nonnull image))completion;

+ (UIViewController* __nonnull)editControllerWithImage:(UIImage* __nonnull)image completion:(void (^ __nonnull) (UIImage * __nonnull image))completion cancel:(void (^ __nonnull) (void))cancel;

@end
