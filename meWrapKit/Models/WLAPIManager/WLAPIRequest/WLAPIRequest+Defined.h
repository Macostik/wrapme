//
//  WLAPIRequest+DefinedRequests.h
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLAPIRequest (Defined)

+ (instancetype)candy:(WLCandy*)candy;

+ (instancetype)deleteCandy:(WLCandy*)candy;

+ (instancetype)deleteComment:(WLComment*)comment;

+ (instancetype)deleteWrap:(WLWrap*)wrap;

+ (instancetype)leaveWrap:(WLWrap *)wrap;

+ (instancetype)followWrap:(WLWrap*)wrap;

+ (instancetype)unfollowWrap:(WLWrap *)wrap;

+ (instancetype)postComment:(WLComment*)comment;

+ (instancetype)resendConfirmation:(NSString*)email;

+ (instancetype)resendInvite:(WLWrap*)wrap user:(WLUser*)user;

+ (instancetype)user:(WLUser*)user;

+ (instancetype)preferences:(WLWrap*)wrap;

+ (instancetype)changePreferences:(WLWrap*)wrap;

+ (instancetype)contributors:(WLWrap*)wrap;

+ (instancetype)verificationCall;

+ (instancetype)uploadMessage:(WLMessage*)message;

+ (instancetype)addContributors:(NSArray*)contributors wrap:(WLWrap*)wrap;

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(WLWrap*)wrap;

+ (instancetype)uploadWrap:(WLWrap*)wrap;

+ (instancetype)updateUser:(WLUser*)user email:(NSString*)email;

+ (instancetype)uploadCandy:(WLCandy*)candy;

+ (instancetype)editCandy:(WLCandy*)candy;

+ (instancetype)updateWrap:(WLWrap*)wrap;

+ (instancetype)contributorsFromContacts:(NSArray*)contacts;

@end
