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
        request = [self GET:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier];
    } else {
        request = [self GET:@"entities/%@", candy.identifier];
    }
    return [[request parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        success(candy.valid ? [candy update:[Candy API_prefetchDictionary:response.data[WLCandyKey]]] : nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteCandy:(Candy *)candy {
    return [[[self DELETE:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [candy remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (candy.uploaded && error.isContentUnavaliable) {
            [candy remove];
        }
    }];
}

+ (instancetype)deleteComment:(Comment *)comment {
    WLAPIRequest *request = [WLAPIRequest DELETE:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.identifier, comment.candy.identifier, comment.identifier];
    return [request parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        Candy *candy = comment.candy;
        [comment remove];
        if (candy.valid) {
            candy.commentCount = [response.data[WLCommentCountKey] intValue];
        }
        success(nil);
    }];
}

+ (instancetype)deleteWrap:(Wrap *)wrap {
    return [[[self DELETE:@"wraps/%@", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap remove];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)leaveWrap:(Wrap *)wrap {
    return [[[self DELETE:@"wraps/%@/leave", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.isPublic) {
            [[wrap mutableContributors] removeObject:[User currentUser]];
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

+ (instancetype)followWrap:(Wrap *)wrap {
    return [[[self POST:@"wraps/%@/follow", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [wrap touch];
        [[wrap mutableContributors] addObject:[User currentUser]];
        [wrap notifyOnUpdate];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)unfollowWrap:(Wrap *)wrap {
    return [[[self DELETE:@"wraps/%@/unfollow", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [[[User currentUser] mutableWraps] removeObject:wrap];
        [wrap notifyOnUpdate];
        success(nil);
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)postComment:(Comment *)comment {
    return [[[self POST:@"wraps/%@/candies/%@/comments", comment.candy.wrap.identifier, comment.candy.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:comment.text forKey:@"message"];
        [parameters trySetObject:comment.uploadIdentifier forKey:@"upload_uid"];
        [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        Candy *candy = comment.candy;
        if (candy.valid) {
            [comment map:[response.data dictionaryForKey:@"comment"]];
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

+ (instancetype)resendInvite:(Wrap *)wrap user:(User *)user {
    return [[self POST:@"wraps/%@/resend_invitation", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.identifier forKey:WLUserUIDKey];
    }];
}

+ (instancetype)user:(User *)user {
    return [[self GET:@"users/%@", user.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        [user map:response.data[@"user"]];
        [user notifyOnUpdate];
        success(user);
    }];
}

+ (instancetype)preferences:(Wrap *)wrap {
    return [[[self GET:@"wraps/%@/preferences", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSDictionary *preference = [response.data dictionaryForKey:WLPreferenceKey];
            wrap.isCandyNotifiable = [[preference numberForKey:WLCandyNotifiableKey] boolValue];
            wrap.isChatNotifiable = [[preference numberForKey:WLChatNotifiableKey] boolValue];
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

+ (instancetype)changePreferences:(Wrap *)wrap {
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

+ (instancetype)contributors:(Wrap *)wrap {
    return [[[self GET:@"wraps/%@/contributors", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSSet *contributors = [[User mappedEntries:[User API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]] set];
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
        [parameters trySetObject:[Authorization currentAuthorization].email forKey:WLEmailKey];
        [parameters trySetObject:[Authorization currentAuthorization].deviceUID forKey:@"device_uid"];
    }];
}

+ (instancetype)uploadMessage:(Message*)message {
    return [[[[self POST:@"wraps/%@/chats", message.wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:message.text forKey:@"message"];
        [parameters trySetObject:message.uploadIdentifier forKey:WLUploadUIDKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (message.wrap.valid) {
            [message map:[response.data dictionaryForKey:WLMessageKey]];
            [message notifyOnUpdate];
            success(message);
        } else {
            success(nil);
        }
    }] beforeFailure:^(NSError *error) {
        Wrap *wrap = message.wrap;
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

+ (instancetype)addContributors:(NSSet*)contributors wrap:(Wrap *)wrap {
    return [[[[self POST:@"wraps/%@/add_contributor", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSMutableSet *_contributors = [NSMutableSet setWithSet:contributors];
        
        NSSet* registeredContributors = [contributors where:@"user != nil"];
        [_contributors minusSet:registeredContributors];
        [parameters trySetObject:[[registeredContributors allObjects] valueForKeyPath:@"user.identifier"] forKey:@"user_uids"];
        
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
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [[User mappedEntries:[User API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]] set];
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

+ (instancetype)removeContributors:(NSArray*)contributors wrap:(Wrap *)wrap {
    return [[[[self DELETE:@"wraps/%@/remove_contributor", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[contributors where:@"user != nil"] valueForKeyPath:@"user.identifier"] forKey:@"user_uids"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet *contributors = [[User mappedEntries:[User API_prefetchArray:[response.data arrayForKey:WLContributorsKey]]] set];
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

+ (instancetype)uploadWrap:(Wrap *)wrap {
    return [[[self POST:@"wraps"] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:wrap.uploadIdentifier forKey:WLUploadUIDKey];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            [wrap map:response.data[WLWrapKey]];
            [wrap notifyOnAddition];
            success(wrap);
        } else {
            success(nil);
        }
    }];
}

+ (instancetype)updateUser:(User *)user email:(NSString*)email {
    return [[[[self PUT:@"users/update"] file:^NSString *(id request) {
        return user.picture.large;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:user.name forKey:WLNameKey];
        [parameters trySetObject:email forKey:WLEmailKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSDictionary* userData = response.data[@"user"];
        Authorization* authorization = [Authorization currentAuthorization];
        [authorization updateWithUserData:userData];
        [user map:userData];
        User.currentUser = user;
        [user notifyOnUpdate];
        success(user);
    }];
}

+ (instancetype)uploadCandy:(Candy *)candy {
    return [[[[[self POST:@"wraps/%@/candies", candy.wrap.identifier] file:^NSString *(id request) {
        return candy.picture.original;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
        [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
        Comment *firstComment = [[candy.comments where:@"uploading == nil"] anyObject];
        if (firstComment) {
            [parameters trySetObject:firstComment.text forKey:@"message"];
            [parameters trySetObject:firstComment.uploadIdentifier forKey:@"message_upload_uid"];
        }
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (candy.wrap.valid) {
            Asset* oldPicture = [candy.picture copy];
            [candy map:[response.data dictionaryForKey:WLCandyKey]];
            [oldPicture cacheForAsset:candy.picture];
            success(candy);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if ([error isError:WLErrorUploadFileNotFound]) {
            [candy remove];
        } else {
            Wrap *wrap = candy.wrap;
            if (wrap.uploaded && error.isContentUnavaliable) {
                [candy remove];
                [wrap remove];
            }
        }
    }];
}

+ (instancetype)editCandy:(Candy *)candy {
    return [[[[[self PUT:@"wraps/%@/candies/%@/", candy.wrap.identifier, candy.identifier] file:^NSString *(id request) {
        return candy.picture.original;
    }] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:@([candy.updatedAt timestamp]) forKey:WLContributedAtKey];
        candy.uploadIdentifier = [NSString GUID];
        [parameters trySetObject:candy.uploadIdentifier forKey:WLUploadUIDKey];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (candy.wrap.valid) {
            Asset* oldPicture = [candy.picture copy];
            [candy map:[response.data dictionaryForKey:WLCandyKey]];
            [oldPicture cacheForAsset:candy.picture];
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

+ (instancetype)updateWrap:(Wrap *)wrap {
    return [[[[self PUT:@"wraps/%@", wrap.identifier] parametrize:^(id request, NSMutableDictionary *parameters) {
        [parameters trySetObject:wrap.name forKey:@"name"];
        [parameters trySetObject:@(wrap.isRestrictedInvite) forKey:@"is_restricted_invite"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            [wrap map:response.data[WLWrapKey]];
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

+ (instancetype)contributorsFromContacts:(NSSet*)contacts {
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
                        phoneNumber.activated = [[userData numberForKey:WLSignInCountKey] integerValue] > 0;
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
