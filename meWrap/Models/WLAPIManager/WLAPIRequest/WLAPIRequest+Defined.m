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
#import "NSArray+WLCollection.h"

@implementation WLAPIRequest (Defined)

- (instancetype)contributionUnavailable:(Contribution *)contribution {
    return [self beforeFailure:^(NSError *error) {
        if (contribution.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [contribution remove];
        }
    }];
}

+ (instancetype)candy:(Candy *)candy {
    WLAPIRequest *request = nil;
    if (candy.wrap) {
        request = [[self GET] path:@"wraps/%@/candies/%@", candy.wrap.uid, candy.uid];
    } else {
        request = [[self GET] path:@"entities/%@", candy.uid];
    }
    return [[request parse:^id (Response *response) {
        return [candy.validEntry update:[Candy prefetchDictionary:response.data[@"candy"]]];
    }] contributionUnavailable:candy];
}

+ (instancetype)deleteCandy:(Candy *)candy {
    return [[[[self DELETE] path:@"wraps/%@/candies/%@", candy.wrap.uid, candy.uid] parse:^id (Response *response) {
        [candy remove];
        return nil;
    }] contributionUnavailable:candy];
}

+ (instancetype)deleteComment:(Comment *)comment {
    WLAPIRequest *request = [[self DELETE] path:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.uid, comment.candy.uid, comment.uid];
    return [request parse:^id (Response *response) {
        Candy *candy = comment.candy;
        [comment remove];
        candy.validEntry.commentCount = [response.data[@"comment_count"] intValue];
        return nil;
    }];
}

+ (instancetype)deleteWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@", wrap.uid] parse:^id (Response *response) {
        [wrap remove];
        return nil;
    }] contributionUnavailable:wrap];
}

+ (instancetype)leaveWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@/leave", wrap.uid] parse:^id (Response *response) {
        if (wrap.isPublic) {
            [[wrap mutableContributors] removeObject:[User currentUser]];
            [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        } else {
            [wrap remove];
        }
        return nil;
    }] contributionUnavailable:wrap];
}

+ (instancetype)followWrap:(Wrap *)wrap {
    return [[[[self POST] path:@"wraps/%@/follow", wrap.uid] parse:^id (Response *response) {
        [wrap touch];
        [[wrap mutableContributors] addObject:[User currentUser]];
        [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        return nil;
    }] contributionUnavailable:wrap];
}

+ (instancetype)unfollowWrap:(Wrap *)wrap {
    return [[[[self DELETE] path:@"wraps/%@/unfollow", wrap.uid] parse:^id (Response *response) {
        [[[User currentUser] mutableWraps] removeObject:wrap];
        [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        return nil;
    }] contributionUnavailable:wrap];
}

+ (instancetype)postComment:(Comment *)comment {
    return [[[[self POST] path:@"wraps/%@/candies/%@/comments", comment.candy.wrap.uid, comment.candy.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:comment.text forKey:@"message"];
        [parameters trySetObject:comment.locuid forKey:@"upload_uid"];
        [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^id (Response *response) {
        Candy *candy = comment.candy;
        if (candy.valid) {
            [comment map:[response.data dictionaryForKey:@"comment"]];
            [candy touch:comment.createdAt];
            int commentCount = [response.data[@"comment_count"] intValue];
            if (candy.commentCount < commentCount)
                candy.commentCount = commentCount;
            return comment;
        } else {
            return nil;
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
    return [[[self GET] path:@"users/%@", user.uid] parse:^id (Response *response) {
        [user map:response.data[@"user"]];
        [user notifyOnUpdate:EntryUpdateEventDefault];
        return user;
    }];
}

+ (instancetype)preferences:(Wrap *)wrap {
    return [[[[self GET] path:@"wraps/%@/preferences", wrap.uid] parse:^id (Response *response) {
        Wrap *wrap = wrap.validEntry;
        NSDictionary *preference = [response.data dictionaryForKey:@"wrap_preference"];
        wrap.isCandyNotifiable = [[preference numberForKey:@"notify_when_image_candy_addition"] boolValue];
        wrap.isChatNotifiable = [[preference numberForKey:@"notify_when_chat_addition"] boolValue];
        [wrap notifyOnUpdate:EntryUpdateEventPreferencesChanged];
        return wrap;
    }] contributionUnavailable:wrap];
}

+ (instancetype)changePreferences:(Wrap *)wrap {
    return [[[[[self PUT] path:@"wraps/%@/preferences", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:@(wrap.isCandyNotifiable) forKey:@"notify_when_image_candy_addition"];
        [parameters trySetObject:@(wrap.isChatNotifiable) forKey:@"notify_when_chat_addition"];
    }] parse:^id (Response *response) {
        return wrap.validEntry;
    }] contributionUnavailable:wrap];
}

+ (instancetype)contributors:(Wrap *)wrap {
    return [[[[self GET] path:@"wraps/%@/contributors", wrap.uid] parse:^id (Response *response) {
        NSSet *contributors = [NSSet setWithArray:[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]]];
        Wrap *wrap = wrap.validEntry;
        if (![wrap.contributors isEqualToSet:contributors]) {
            wrap.contributors = contributors;
        }
        return contributors;
    }] contributionUnavailable:wrap];
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
    }] parse:^id (Response *response) {
        if (message.wrap.valid) {
            [message map:[response.data dictionaryForKey:@"chat"]];
            [message notifyOnUpdate:EntryUpdateEventContentAdded];
            return message;
        } else {
            return nil;
        }
    }] contributionUnavailable:message.wrap];
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
    }] parse:^id (Response *response) {
        Wrap *wrap = wrap.validEntry;
        NSSet *contributors = [NSSet setWithArray:[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]]];
        if (![wrap.contributors isEqualToSet:contributors]) {
            wrap.contributors = contributors;
            [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        }
        return wrap;
    }] contributionUnavailable:wrap];
}

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(Wrap *)wrap {
    return [[[[[self DELETE] path:@"wraps/%@/remove_contributor", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[contributors where:@"user != nil"] valueForKeyPath:@"user.uid"] forKey:@"user_uids"];
    }] parse:^id (Response *response) {
        Wrap *wrap = wrap.validEntry;
        NSSet *contributors = [NSSet setWithArray:[User mappedEntries:[User prefetchArray:[response.data arrayForKey:@"contributors"]]]];
        if (![wrap.contributors isEqualToSet:contributors]) {
            wrap.contributors = contributors;
            [wrap notifyOnUpdate:EntryUpdateEventContributorsChanged];
        }
        return wrap;
    }] contributionUnavailable:wrap];
}

+ (instancetype)uploadWrap:(Wrap *)wrap {
    return [[[[self POST] path:@"wraps"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:wrap.locuid forKey:@"upload_uid"];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^id (Response *response) {
        Wrap *wrap = wrap.validEntry;
        [wrap map:response.data[@"wrap"]];
        [wrap notifyOnAddition];
        return wrap;
    }];
}

+ (instancetype)updateUser:(User *)user email:(NSString*)email {
    return [[[[[self PUT] path:@"users/update"] file:^NSString *(id request) {
        return user.avatar.large;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.name forKey:@"name"];
        [parameters trySetObject:email forKey:@"email"];
    }] parse:^id (Response *response) {
        NSDictionary* userData = response.data[@"user"];
        Authorization* authorization = [Authorization currentAuthorization];
        [authorization updateWithUserData:userData];
        [user map:userData];
        User.currentUser = user;
        [user notifyOnUpdate:EntryUpdateEventDefault];
        return user;
    }];
}

+ (instancetype)updateWrap:(Wrap *)wrap {
    return [[[[[self PUT] path:@"wraps/%@", wrap.uid] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:@(wrap.isRestrictedInvite) forKey:@"is_restricted_invite"];
    }] parse:^id (Response *response) {
        Wrap *wrap = wrap.validEntry;
        [wrap map:response.data[@"wrap"]];
        [wrap notifyOnUpdate:EntryUpdateEventDefault];
        return wrap;
    }] contributionUnavailable:wrap];
}

+ (instancetype)contributorsFromContacts:(NSArray*)contacts {
    return [[[[self POST] path:@"users/sign_up_status"] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableArray* phones = [NSMutableArray array];
        for (WLAddressBookRecord* contact in contacts) {
            for (WLAddressBookPhoneNumber* phoneNumber in contact.phoneNumbers) {
                [phones addObject:phoneNumber.phone];
            }
        }
        [parameters trySetObject:phones forKey:@"phone_numbers"];
    }] parse:^id (Response *response) {
        NSArray* users = response.data[@"users"];
        NSMutableSet *registeredUsers = [NSMutableSet set];
        NSArray *contributors = [contacts map:^id(WLAddressBookRecord* contact) {
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
        return contributors;
    }];
}

+ (instancetype)postCandy:(Candy *)candy violationCode:(NSString *)violationCode {
    return [[[[self POST] path:@"wraps/%@/candies/%@/violations/", candy.wrap.uid, candy.uid] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:violationCode forKey:@"violation_code"];
    }] parse:^id (Response *response) {
        if  (candy.wrap.valid) {
            return candy;
        }else {
            return nil;
        }
    }];
}

@end
