//
//  WLImageEditorSession.h
//  meWrap
//
//  Created by Sergey Maximenko on 10/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^WLImageEditingCompletionBlock) (UIImage *image);
typedef void(^WLImageEditingCancelBlock) (void);

@interface WLImageEditorSession : NSObject

+ (void)editImage:(UIImage *)image completion:(ImageBlock)completion cancel:(Block)cancel;

+ (UIViewController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel;

@end
