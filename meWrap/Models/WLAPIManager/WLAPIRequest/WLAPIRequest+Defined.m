//
//  WLAPIRequest+DefinedRequests.m
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest+Defined.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

@implementation WLAPIRequest (Defined)

+ (instancetype)candy:(Candy *)candy {
    WLAPIRequest *request = nil;
    if (candy.wrap) {
        request = [[self GET] path:@"wraps/%@/candies/%@", candy.wrap.uid, candy.uid];
    } else {
        request = [[self GET] path:@"entities/%@", candy.uid];
    }
    return [[request parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        success(candy.valid ? [candy update:[Candy prefetchDictionary:response.data[@"candy"]]] : nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteCandy:(Candy *)candy {
    return [[[[self DELETE] path:@"wraps/%@/candies/%@", candy.wrap.uid, candy.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        [candy remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteComment:(Comment *)comment {
    WLAPIRequest *request = [[self DELETE] path:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.uid, comment.candy.uid, comment.uid];
    return [request parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        Candy *candy = comment.candy;
        [comment remove];
        if (candy.valid) {
            candy.commentCount = [response.data[@"comment_count"] intValue];
        }
        success(nil);
    }];
}

+ (instancetype)deleteWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        [wrap remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)leaveWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@/leave", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.isPublic) {
            [[wrap mutableContributors] removeObject:[User currentUser]];
            [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        } else {
            [wrap remove];
        }
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)followWrap:(Wrap *)wrap {
    return [[[[self POST] path:@"wraps/%@/follow", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        [wrap touch];
        [[wrap mutableContributors] addObject:[User currentUser]];
        [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)unfollowWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@/unfollow", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        [[[User currentUser] mutableWraps] removeObject:wrap];
        [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)postComment:(Comment *)comment {
    return [[[[self POST] path:@"wraps/%@/candies/%@/comments", comment.candy.wrap.uid, comment.candy.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:comment.text forKey:@"message"];
        [parameters trySetObject:comment.locuid forKey:@"upload_uid"];
        [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        Candy *candy = comment.candy;
        if (candy.valid) {
            [comment map:[response.data dictionaryForKey:@"comment"]];
            [candy touch:comment.createdAt];
            int commentCount = [response.data[@"comment_count"] intValue];
            if (candy.commentCount < commentCount)
                candy.commentCount = commentCount;
            success(comment);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)resendConfirmation:(NSString*)email {
    return [[[self POST] path:@"users/resend_confirmation"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:email forKey:@"email"];
    }];
}

+ (instancetype)resendInvite:(Wrap *)wrap user:(User *)user {
    return [[[self POST] path:@"wraps/%@/resend_invitation", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.uid forKey:@"user_uid"];
    }];
}

+ (instancetype)user:(User *)user {
    return [[[self GET] path:@"users/%@", user.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        [user map:response.data[@"user"]];
        [user notifyOnUpdate:EntryUpdateEventDefault];
        success(user);
    }];
}

+ (instancetype)preferences:(Wrap *)wrap {
    return [[[[self GET] path:@"wraps/%@/preferences", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            NSDictionary *preference = [response.data dictionaryForKey:@"wrap_preference"];
            wrap.isCandyNotifiable = [[preference numberForKey:@"notify_when_image_candy_addition"] boolValue];
            wrap.isChatNotifiable = [[preference numberForKey:@"notify_when_chat_addition"] boolValue];
            [wrap notifyOnUpdate:EntryUpdateEventPreferencesChanged];
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)changePreferences:(Wrap *)wrap {
    return [[[[[self PUT] path:@"wraps/%@/preferences", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:@(wrap.isCandyNotifiable) forKey:@"notify_when_image_candy_addition"];
        [parameters trySetObject:@(wrap.isChatNotifiable) forKey:@"notify_when_chat_addition"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)contributors:(Wrap *)wrap {
    return [[[[self GET] path:@"wraps/%@/contributors", wrap.uid] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        NSSet *contributors = [[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]] set];
        if (wrap.valid && ![wrap.contributors isEqualToSet:contributors]) {
            wrap.contributors = contributors;
        }
        success(contributors);
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)verificationCall {
    return [[[self POST] path:@"users/call"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[Authorization currentAuthorization].email forKey:@"email"];
        [parameters trySetObject:[Authorization currentAuthorization].deviceUID forKey:@"device_uid"];
    }];
}

+ (instancetype)uploadMessage:(Message*)message {
    return [[[[[self POST] path:@"wraps/%@/chats", message.wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:message.text forKey:@"message"];
        [parameters trySetObject:message.locuid forKey:@"upload_uid"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (message.wrap.valid) {
            [message map:[response.data dictionaryForKey:@"chat"]];
            [message notifyOnUpdate:EntryUpdateEventContentAdded];
            success(message);
        } else {
            success(nil);
        }
    }] beforeFailure:^(NSError *error) {
        Wrap *wrap = message.wrap;
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)addContributors:(NSSet*)contributors wrap:(Wrap *)wrap message:(NSString *)message {
    return [[[[[self POST] path:@"wraps/%@/add_contributor", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableSet *_contributors = [NSMutableSet setWithSet:contributors];
        
        NSSet* registeredContributors = [contributors where:@"user != nil"];
        [_contributors minusSet:registeredContributors];
        [parameters trySetObject:[[registeredContributors allObjects] valueForKeyPath:@"user.uid"] forKey:@"user_uids"];
        [parameters trySetObject:message forKey:@"message"];
        
        NSMutableArray *invitees = [NSMutableArray array];
        
        while (_contributors.nonempty) {
            WLAddressBookPhoneNumber *_person = [_contributors anyObject];
            if (_person.record) {
                NSSet *groupedContributors = [_contributors where:@"record == %@", _person.record];
                [invitees addObject:@{@"name":_person.name?:@"",@"phone_numbers":[[groupedContributors valueForKey:@"phone"] array]}];
                [_contributors minusSet:groupedContributors];
            } else {
                [invitees addObject:@{@"name":_person.name?:@"",@"phone_number":_person.phone}];
                [_contributors removeObject:_person];
            }
        }
        [parameters trySetObject:[invitees map:^id(NSDictionary *data) {
            NSData* invitee = [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
            return [[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding];
        }] forKey:@"invitees"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]] set];
            if (![wrap.contributors isEqualToSet:contributors]) {
                wrap.contributors = contributors;
                [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
            }
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(Wrap *)wrap {
    return [[[[[self DELETE] path:@"wraps/%@/remove_contributor", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[contributors where:@"user != nil"] valueForKeyPath:@"user.uid"] forKey:@"user_uids"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]] set];
            if (![wrap.contributors isEqualToSet:contributors]) {
                wrap.contributors = contributors;
                [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
            }
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)uploadWrap:(Wrap *)wrap {
    return [[[[self POST] path:@"wraps"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:wrap.locuid forKey:@"upload_uid"];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            [wrap map:response.data[@"wrap"]];
            [wrap notifyOnAddition];
            success(wrap);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)updateUser:(User *)user email:(NSString*)email {
    return [[[[[self PUT] path:@"users/update"] file:^NSString *(id request) {
        return user.avatar.large;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.name forKey:@"name"];
        [parameters trySetObject:email forKey:@"email"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        NSDictionary* userData = response.data[@"user"];
        Authorization* authorization = [Authorization currentAuthorization];
        [authorization updateWithUserData:userData];
        [user map:userData];
        User.currentUser = user;
        [user notifyOnUpdate:EntryUpdateEventDefault];
        success(user);
    }];
}

+ (instancetype)updateWrap:(Wrap *)wrap {
    return [[[[[self PUT] path:@"wraps/%@", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:@(wrap.isRestrictedInvite) forKey:@"is_restricted_invite"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (wrap.valid) {
            [wrap map:response.data[@"wrap"]];
            [wrap notifyOnUpdate:EntryUpdateEventDefault];
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

+ (instancetype)contributorsFromContacts:(NSSet*)contacts {
    return [[[[self POST] path:@"users/sign_up_status"] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableArray* phones = [NSMutableArray array];
        [contacts all:^(WLAddressBookRecord* contact) {
            [contact.phoneNumbers all:^(WLAddressBookPhoneNumber* person) {
                [phones addObject:person.phone];
            }];
        }];
        [parameters trySetObject:phones forKey:@"phone_numbers"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        NSArray* users = response.data[@"users"];
        NSMutableSet *registeredUsers = [NSMutableSet set];
        NSSet *contributors = [contacts map:^id(WLAddressBookRecord* contact) {
            contact.phoneNumbers = [contact.phoneNumbers map:^id(WLAddressBookPhoneNumber *phoneNumber) {
                NSDictionary *userData = [[users where:@"address_book_number == %@", phoneNumber.phone] lastObject];
                if (userData) {
                    User *user = [User mappedEntry:userData];
                    if (user) {
                        if ([user current] || [registeredUsers containsObject:user]) {
                            return nil;
                        }
                        [registeredUsers addObject:user];
                        phoneNumber.user = user;
                        phoneNumber.activated = [[userData numberForKey:@"sign_in_count"] integerValue] > 0;
                    }
                }
                return phoneNumber;
            }];
            return contact.phoneNumbers.nonempty ? contact : nil;
        }];
        success(contributors);
    }];
}

+ (instancetype)postCandy:(Candy *)candy violationCode:(NSString *)violationCode {
    return [[[[self POST] path:@"wraps/%@/candies/%@/violations/", candy.wrap.uid, candy.uid] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:violationCode forKey:@"violation_code"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if  (candy.wrap.valid) {
            success(candy);
        }else {
            success(nil);
        }
    }];
}

@end
