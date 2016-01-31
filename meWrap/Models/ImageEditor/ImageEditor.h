//
//  ImageEditor.h
//  meWrap
//
//  Created by Sergey Maximenko on 10/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageEditor : NSObject

+ (void)editImage:(UIImage *)image completion:(ImageBlock)completion cancel:(Block)cancel;

+ (UIViewController*)editControllerWithImage:(UIImage*)image completion:(ImageBlock)completion cancel:(Block)cancel;

@end
