//
//  WLAPIRequest+DefinedRequests.m
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAPIRequest+Defined.h"
#import "WLEntryNotifier.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

@implementation WLAPIRequest (Defined)

+ (instancetype)candy:(WLCandy *)candy {
    WLAPIRequest *request = nil;
    if (candy.wrap) {
        request = [self GET:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier];
    } else {
        request = [self GET:@"entities/%@", candy.identifier];
    }
    return [[request parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        success(candy.valid ? [candy update:[WLCandy API_prefetchDictionary:response.data[WLCandyKey]]] : nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteCandy:(WLCandy *)candy {
    return [[[self DELETE:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [candy remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteComment:(WLComment *)comment {
    WLAPIRequest *request = [WLAPIRequest DELETE:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.identifier, comment.candy.identifier, comment.identifier];
    return [request parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLCandy *candy = comment.candy;
        [comment remove];
        if (candy.valid) {
            candy.commentCount = [response.data[WLCommentCountKey] intValue];
        }
        success(nil);
    }];
}

+ (instancetype)deleteWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)leaveWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@/leave", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.isPublic) {
            [wrap removeContributorsObject:[WLUser currentUser]];
            [wrap notifyOnUpdate];
        } else {
            [wrap remove];
        }
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)followWrap:(WLWrap *)wrap {
    return [[[self POST:@"wraps/%@/follow", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap touch];
        [wrap addContributorsObject:[WLUser currentUser]];
        [wrap notifyOnUpdate];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)unfollowWrap:(WLWrap *)wrap {
    return [[[self DELETE:@"wraps/%@/unfollow", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [[WLUser currentUser] removeWrap:wrap];
        [wrap notifyOnUpdate];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)postComment:(WLComment*)comment {
    return [[[self POST:@"wraps/%@/candies/%@/comments", comment.candy.wrap.identifier, comment.candy.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:comment.text forKey:@"message"];
        [parameters trySetObject:comment.uploadIdentifier forKey:@"upload_uid"];
        [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLCandy *candy = comment.candy;
        if (candy.valid) {
            [comment API_setup:[response.data dictionaryForKey:@"comment"]];
            [candy touch:comment.createdAt];
            int commentCount = [response.data[WLCommentCountKey] intValue];
            if (candy.commentCount < commentCount)
                candy.commentCount = commentCount;
            success(comment);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)resendConfirmation:(NSString*)email {
    return [[self POST:@"users/resend_confirmation"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:email forKey:WLEmailKey];
    }];
}

+ (instancetype)resendInvite:(WLWrap*)wrap user:(WLUser*)user {
    return [[self POST:@"wraps/%@/resend_invitation", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.identifier forKey:WLUserUIDKey];
    }];
}

+ (instancetype)user:(WLUser*)user {
    return [[self GET:@"users/%@", user.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [user API_setup:response.data[@"user"]];
        [user notifyOnUpdate];
        success(user);
    }];
}

+ (instancetype)preferences:(WLWrap*)wrap {
    return [[[self GET:@"wraps/%@/preferences", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSDictionary *preference = [response.data dictionaryForKey:WLPreferenceKey];
            wrap.isCandyNotifiable = [preference boolForKey:WLCandyNotifiableKey];
            wrap.isChatNotifiable = [preference boolForKey:WLChatNotifiableKey];
            [wrap notifyOnUpdate];
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)changePreferences:(WLWrap*)wrap {
    return [[[[self PUT:@"wraps/%@/preferences", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:@(wrap.isCandyNotifiable) forKey:WLCandyNotifiableKey];
        [parameters trySetObject:@(wrap.isChatNotifiable) forKey:WLChatNotifiableKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)contributors:(WLWrap*)wrap {
    return [[[self GET:@"wraps/%@/contributors", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSSet *contributors = [WLUser API_entries:[WLUser API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]];
        if (wrap.valid && ![wrap.contributors isEqualToSet:contributors]) {
            wrap.contributors = contributors;
        }
        success(contributors);
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)verificationCall {
    return [[self POST:@"users/call"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[WLAuthorization currentAuthorization].email forKey:WLEmailKey];
        [parameters trySetObject:[WLAuthorization currentAuthorization].deviceUID forKey:@"device_uid"];
    }];
}

+ (instancetype)uploadMessage:(WLMessage*)message {
    return [[[[self POST:@"wraps/%@/chats", message.wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:message.text forKey:@"message"];
        [parameters trySetObject:message.uploadIdentifier forKey:WLUploadUIDKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (message.wrap.valid) {
            [message API_setup:[response.data dictionaryForKey:WLMessageKey]];
            [message notifyOnUpdate];
            success(message);
        } else {
            success(nil);
        }
    }] beforeFailure:^(NSError *error) {
        WLWrap *wrap = message.wrap;
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)addContributors:(NSArray*)contributors wrap:(WLWrap*)wrap {
    return [[[[self POST:@"wraps/%@/add_contributor", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableArray *_contributors = [NSMutableArray arrayWithArray:contributors];
        
        NSArray* registeredContributors = [contributors where:@"user != nil"];
        [_contributors removeObjectsInArray:registeredContributors];
        [parameters trySetObject:[registeredContributors valueForKeyPath:@"user.identifier"] forKey:@"user_uids"];
        
        NSMutableArray *invitees = [NSMutableArray array];
        
        while (_contributors.nonempty) {
            WLAddressBookPhoneNumber *_person = [contributors firstObject];
            if (_person.record) {
                NSArray *groupedContributors = [contributors where:@"record == %@", _person.record];
                [invitees addObject:@{@"name":WLString(_person.name),@"phone_numbers":[groupedContributors valueForKey:@"phone"]}];
                [_contributors removeObjectsInArray:groupedContributors];
            } else {
                [invitees addObject:@{@"name":WLString(_person.name),@"phone_number":_person.phone}];
                [_contributors removeObject:_person];
            }
        }
        [parameters trySetObject:[invitees map:^id(NSDictionary *data) {
            NSData* invitee = [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
            return [[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding];
        }] forKey:@"invitees"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [WLUser API_entries:[WLUser API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]];
            if (![wrap.contributors isEqualToSet:contributors]) {
                wrap.contributors = contributors;
                [wrap notifyOnUpdate];
            }
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(WLWrap*)wrap {
    return [[[[self DELETE:@"wraps/%@/remove_contributor", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[contributors where:@"user != nil"] valueForKeyPath:@"user.identifier"] forKey:@"user_uids"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [WLUser API_entries:[WLUser API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]];
            if (![wrap.contributors isEqualToSet:contributors]) {
                wrap.contributors = contributors;
                [wrap notifyOnUpdate];
            }
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)uploadWrap:(WLWrap*)wrap {
    return [[[self POST:@"wraps"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:wrap.uploadIdentifier forKey:WLUploadUIDKey];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            [wrap API_setup:response.data[WLWrapKey]];
            [wrap notifyOnAddition];
            success(wrap);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)updateUser:(WLUser*)user email:(NSString*)email {
    return [[[[self PUT:@"users/update"] file:^NSString *(id request) {
        return user.picture.large;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.name forKey:WLNameKey];
        [parameters trySetObject:email forKey:WLEmailKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSDictionary* userData = response.data[@"user"];
        WLAuthorization* authorization = [WLAuthorization currentAuthorization];
        [authorization updateWithUserData:userData];
        [user API_setup:userData];
        [user setCurrent];
        [user notifyOnUpdate];
        success(user);
    }];
}

+ (instancetype)uploadCandy:(WLCandy*)candy {
    return [[[[[self POST:@"wraps/%@/candies", candy.wrap.identifier] file:^NSString *(id request) {
        return candy.picture.original;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
        [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
        WLComment *firstComment = [[candy.comments where:@"uploading == nil"] anyObject];
        if (firstComment) {
            [parameters trySetObject:firstComment.text forKey:@"message"];
            [parameters trySetObject:firstComment.uploadIdentifier forKey:@"message_upload_uid"];
        }
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (candy.wrap.valid) {
            WLPicture* oldPicture = [candy.picture copy];
            [candy API_setup:[response.data dictionaryForKey:WLCandyKey]];
            [oldPicture cacheForPicture:candy.picture];
            success(candy);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if ([error isError:WLErrorUploadFileNotFound]) {
            [candy remove];
        } else {
            WLWrap *wrap = candy.wrap;
            if (wrap.uploaded && error.isContentUnavaliable) {
                [candy remove];
                [wrap remove];
            }
        }
    }];
}

+ (instancetype)editCandy:(WLCandy*)candy {
    return [[[[[self PUT:@"wraps/%@/candies/%@/", candy.wrap.identifier, candy.identifier] file:^NSString *(id request) {
        return candy.picture.original;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
        candy.uploadIdentifier = GUID();
        [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (candy.wrap.valid) {
            WLPicture* oldPicture = [candy.picture copy];
            [candy API_setup:[response.data dictionaryForKey:WLCandyKey]];
            [oldPicture cacheForPicture:candy.picture];
            success(candy);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if ([error isError:WLErrorContentUnavaliable]) {
            [candy remove];
        }
    }];
}

+ (instancetype)updateWrap:(WLWrap*)wrap {
    return [[[[self PUT:@"wraps/%@", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:@(wrap.isRestrictedInvite) forKey:@"is_restricted_invite"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            [wrap API_setup:response.data[WLWrapKey]];
            [wrap notifyOnUpdate];
            success(wrap);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)contributorsFromContacts:(NSArray*)contacts {
    return [[[self POST:@"users/sign_up_status"] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableArray* phones = [NSMutableArray array];
        [contacts all:^(WLAddressBookRecord* contact) {
            [contact.phoneNumbers all:^(WLAddressBookPhoneNumber* person) {
                [phones addObject:person.phone];
            }];
        }];
        [parameters trySetObject:phones forKey:@"phone_numbers"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSArray* users = response.data[@"users"];
        NSMutableSet *registeredUsers = [NSMutableSet set];
        NSArray *contributors = [contacts map:^id(WLAddressBookRecord* contact) {
            contact.phoneNumbers = [contact.phoneNumbers map:^id(WLAddressBookPhoneNumber *phoneNumber) {
                NSDictionary *userData = [[users where:@"address_book_number == %@", phoneNumber.phone] lastObject];
                if (userData) {
                    WLUser *user = [WLUser API_entry:userData];
                    if (user) {
                        if ([user isCurrentUser] || [registeredUsers containsObject:user]) {
                            return nil;
                        }
                        [registeredUsers addObject:user];
                        phoneNumber.user = user;
                        phoneNumber.activated = [userData integerForKey:WLSignInCountKey] > 0;
                    }
                }
                return phoneNumber;
            }];
            return contact.phoneNumbers.nonempty ? contact : nil;
        }];
        success(contributors);
    }];
}

+ (instancetype)postCandy:(WLCandy *)candy violationCode:(NSString *)violationCode {
    return [[[[self POST:@"wraps/%@/candies/%@/violations/", candy.wrap.identifier, candy.identifier] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:violationCode forKey:WLCandyViolationKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if  (candy.wrap.valid) {
            success(candy);
        }else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
    }];
}

@end
