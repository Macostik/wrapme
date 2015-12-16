//
//  WLAPIRequest+DefinedRequests.h
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@class Wrap, Candy, User, Comment, Message, Contribution;

@interface WLAPIRequest (Defined)

- (instancetype)contributionUnavailable:(Contribution *)contribution;

+ (instancetype)candy:(Candy *)candy;

+ (instancetype)deleteCandy:(Candy *)candy;

+ (instancetype)deleteComment:(Comment *)comment;

+ (instancetype)deleteWrap:(Wrap *)wrap;

+ (instancetype)leaveWrap:(Wrap *)wrap;

+ (instancetype)followWrap:(Wrap *)wrap;

+ (instancetype)unfollowWrap:(Wrap *)wrap;

+ (instancetype)postComment:(Comment *)comment;

+ (instancetype)resendConfirmation:(NSString*)email;

+ (instancetype)resendInvite:(Wrap *)wrap user:(User *)user;

+ (instancetype)user:(User *)user;

+ (instancetype)preferences:(Wrap *)wrap;

+ (instancetype)changePreferences:(Wrap *)wrap;

+ (instancetype)contributors:(Wrap *)wrap;

+ (instancetype)verificationCall;

+ (instancetype)uploadMessage:(Message*)message;

+ (instancetype)addContributors:(NSSet*)contributors wrap:(Wrap *)wrap message:(NSString *)message;

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(Wrap *)wrap;

+ (instancetype)uploadWrap:(Wrap *)wrap;

+ (instancetype)updateUser:(User *)user email:(NSString*)email;

+ (instancetype)updateWrap:(Wrap *)wrap;

+ (instancetype)contributorsFromContacts:(NSArray*)contacts;

+ (instancetype)postCandy:(id)candy violationCode:(NSString *)violationCode;

@end
