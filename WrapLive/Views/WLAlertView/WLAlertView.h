//
//  WLAlertView.h
//  moji
//
//  Created by Yura Granchenko on 04/02/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

typedef void (^WLAlertViewCompletion)(NSUInteger index);

@protocol WLAlertView <NSObject>

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel action:(NSString *)action completion:(void (^)(void))completion;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion;

+ (void)showWithMessage:(NSString*)message;

@end


@interface WLAlertView : NSObject <WLAlertView>

@end

@interface WLAlertView (DefinedAlerts)

+ (void)confirmWrapDeleting:(WLWrap*)wrap success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (void)confirmCandyDeleting:(WLCandy *)candy success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (void)confirmRedirectingToSignUp:(WLBlock)signUp tryAgain:(WLBlock)tryAgain;

@end

@interface UIAlertController (WLAlertView) <WLAlertView>

@end

@interface UIAlertView (WLAlertView) <WLAlertView>

@property (strong, nonatomic) WLAlertViewCompletion completion;

@end
