/******************************************************************************
 *
 * ADOBE CONFIDENTIAL
 * ___________________
 *
 * Copyright 2013 Adobe Systems Incorporated
 * All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains the property of
 * Adobe Systems Incorporated and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Adobe Systems
 * Incorporated and its suppliers and are protected by trade secret or
 * copyright law. Dissemination of this information or reproduction of this
 * material is strictly forbidden unless prior written permission is obtained
 * from Adobe Systems Incorporated.
 *
 * THIS FILE IS PART OF THE CREATIVE SDK PUBLIC API
 *
 ******************************************************************************/

#ifndef AdobeUXAuthManagerHeader
#define AdobeUXAuthManagerHeader

#import <Foundation/Foundation.h>

#ifndef DMALIB
#import <UIKit/UIKit.h>
#endif

#import <AdobeCreativeSDKCore/AdobeAuthError.h>
#import <AdobeCreativeSDKCore/AdobeAuthUserProfile.h>

/**
 * This notification is sent when the authentication fails after a specific number of attempts.
 */
extern NSString *const AdobeAuthManagerTooManyAuthErrorsNotification;

/**
 * This notification is sent through the NSNotificationManager when a user logs in using the AdobeUXAuthManager.
 */
extern NSString *const AdobeAuthManagerLoggedInNotification;

/**
 * This notification is sent through the NSNotificationManager when a user logs out using the AdobeUXAuthManager.
 */
extern NSString *const AdobeAuthManagerLoggedOutNotification;


/**
 * The different modes for the creativeCloudEventLoggingMode property
 */
typedef NS_ENUM (NSInteger, AdobeCCEventLoggingMode)
{
    /** Default: Event logging is on. */
    AdobeCCEventLoggingModeDefault = 0,
    
    /** Test mode: Event logging to test servers only. */
    AdobeCCEventLoggingModeTest = 1,
    
    /** Off: No event logging. */
    AdobeCCEventLoggingModeOff = 2
};

/**
 * AdobeUXAuthManager is the class through which authentication with the Adobe Creative Cloud is managed.
 * This is starting point for using the Creative SDK.  All clients are required to call
 * the setAuthenticationParametersWithClientID:withClientSecret: method before using the CreativeSDK.
 *
 * Using this class, you can:
 *
 * 1. Specify the clientID and clientSecret as issued by Adobe.
 * 2. Query for authentication status.
 * 3. Get the user profile of the currently authenticated user.
 * 4. Logout the currently logged in user.
 *
 * You need to use the sharedManager property for all the interactions.
 *
 * The Login and Logout notifications are sent through the NSNotificationManager class.
 *
 * The NSNotificationManager will send
 *
 * <code>extern NSString\* const AdobeAuthManagerLoggedInNotification</code>
 *
 * when a user login occurs and
 *
 * <code>extern NSString\* const AdobeAuthManagerLoggedOutNotification</code>
 *
 * when a user logout occurs.
 *
 * The AdobeUXAuthManager handles creating the UI for login and account creation automatically.
 * Logins are cached such that when your application starts up, it can login automatically.
 *
 * @note Many Creative SDK APIs will require an authenticated user so nearly all other classes will rely upon this class.
 *
 */
@interface AdobeUXAuthManager : NSObject

/**
 * Returns whether or not there is a currently logged in user.
 *
 * @returns YES if there is an authenticated user, NO if there is no currently logged in user.
 */
@property (nonatomic, readonly, assign, getter = isAuthenticated) BOOL authenticated;

/**
 * Gets the user profile of the currently logged in user.
 *
 * @returns the user profile of the currently logged in user or nil if no user is currently logged in.
 * @see AdobeAuthUserProfile
 */
@property (nonatomic, readonly, strong) AdobeAuthUserProfile *userProfile;

/**
 * Returns a singleton instance of AdobeUXAuthManager for use within your application.
 *
 * @returns the singleton object.
 */
+ (AdobeUXAuthManager *)sharedManager;

/**
 * Sets the authentication parameters for Creative Cloud Authentication.
 *
 * This method must be called once at application startup, typically in the application delegate.
 * It must be called before any other authentication calls.
 *
 * This method does not initiate a login.  If needed, login is triggered when Creative Cloud
 * services are accessed or when AdobeUXAuthManager login:onSuccess:onError is explicitly called.
 *
 * Currently Apple requires supporting in-app purchase before enabling sign up. Contact Adobe to learn
 * about the in-app purchases you can offer through the Creative SDK.  This method enables user sign up.
 *
 * @param clientID The clientID as supplied to the application developer by Adobe
 * @param clientSecret The client secret for the application as supplied to the application developer by Adobe
 */
- (void)setAuthenticationParametersWithClientID:(NSString *)clientID
                               withClientSecret:(NSString *)clientSecret;

/**
 * Sets the authentication parameters for Creative Cloud Authentication.
 *
 * This method has been deprecated and will be obsoleted soon.  Use
 * setAuthenticationParametersWithClientID:withClientSecret: instead.
 *
 * @param clientID The clientID as supplied to the application developer by Adobe
 * @param clientSecret The client secret for the application as supplied to the application developer by Adobe
 * @enableSignUp    Ignored.  This method always enables user sign up.
 *
 */
- (void)setAuthenticationParametersWithClientID:(NSString *)clientID
                                   clientSecret:(NSString *)clientSecret
                                   enableSignUp:(BOOL)enableSignUp
__deprecated_msg("Use setAuthenticationParametersWithClientID:withClientSecret: instead.  User signup is always enabled.");

/**
 * Controls if and how event data gets logged with the Creative Cloud.
 *
 * Default value is AdobeCCEventLoggingModeDefault.
 *
 * Must set this before the call to setAuthenticationParametersWithClientID:...
 */
@property (nonatomic) AdobeCCEventLoggingMode creativeCloudEventLoggingMode;

#ifndef DMALIB

/**
 * Logs in the user. This method creates a view that handles all aspects of account login and account creation.
 *
 * @param parentViewController the view controller that will host any UI elements needed for login
 * @param successBlock the block of code that gets called upon login success
 * @param errorBlock the block of code that gets called upon login failure
 * @note This call is not explicity needed to be called. If authentication is required, it will be called later.
 */
- (void)login:(UIViewController *)parentViewController
    onSuccess:(void (^)(AdobeAuthUserProfile *profile))successBlock
      onError:(void (^)(NSError *error))errorBlock;
#endif

/**
 * Logs out the currently logged in user.
 *
 * @param successBlock the block of code that gets called upon logout success
 * @param errorBlock the block of code that gets called upon logout failure
 */
- (void)logout:(void (^)(void))successBlock
       onError:(void (^)(NSError *error))errorBlock;

@end

#endif
