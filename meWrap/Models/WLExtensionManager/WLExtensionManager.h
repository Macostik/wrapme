//
//  WLExtensionManager.h
//  meWrap
//
//  Created by Sergey Maximenko on 10/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLExtensionManager : NSObject <WLExtensionRequestActions>

+ (void)performRequest:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler;

@end
