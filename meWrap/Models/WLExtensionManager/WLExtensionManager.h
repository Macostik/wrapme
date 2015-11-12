//
//  WLExtensionManager.h
//  meWrap
//
//  Created by Sergey Maximenko on 10/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLExtensionManager : NSObject

+ (void)performRequest:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler;

@end
