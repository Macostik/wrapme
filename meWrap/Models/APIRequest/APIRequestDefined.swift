//
//  APIRequestDefined.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import PubNub

extension APIRequest {
    
    func contributionUnavailable(contribution: Contribution) -> Self {
        return beforeFailure {
            if contribution.uploaded && ($0?.isResponseError(.ContentUnavailable) ?? false) {
                contribution.remove()
            }
        }
    }
    
    class func wrap(wrap: Wrap, contentType: String?) -> Self {
        return GET().path("wraps/%@", wrap.uid).parametrize({ (request) -> Void in
            if let contentType = contentType {
                request["pick"] = contentType
            }
        }).parse({ (response) -> AnyObject! in
            if let dictionary = response.dictionary("wrap") where wrap.valid {
                return wrap.update(Wrap.prefetchDictionary(dictionary))
            } else {
                return nil
            }
        }).contributionUnavailable(wrap)
    }
    
    class func candy(candy: Candy) -> Self {
        var request = GET()
        if let wrap = candy.wrap {
            request = request.path("wraps/\(wrap.uid)/candies/\(candy.uid)")
        } else {
            request = request.path("entities/\(candy.uid)")
        }
        return request.parse({ response in
            if let dictionary = response.dictionary("candy") {
                return candy.validEntry()?.update(Candy.prefetchDictionary(dictionary))
            } else {
                return nil
            }
        }).contributionUnavailable(candy)
    }
    
    class func deleteCandy(candy: Candy) -> Self? {
        guard let wrap = candy.wrap else { return nil }
        return DELETE().path("wraps/\(wrap.uid)/candies/\(candy.uid)").parse { response in
            candy.remove()
            return nil
            }.contributionUnavailable(candy)
    }
    
    class func deleteComment(comment: Comment) -> Self? {
        guard let candy = comment.candy else { return nil }
        guard let wrap = candy.wrap else { return nil }
        return DELETE().path("wraps/\(wrap.uid)/candies/\(candy.uid)/comments/\(comment.uid)").parse { response in
            comment.remove()
            candy.validEntry()?.commentCount = Int16(response.data["comment_count"] as? Int ?? 0)
            return nil
            }.contributionUnavailable(candy)
    }
    
    class func deleteWrap(wrap: Wrap) -> Self {
        return DELETE().path("wraps/\(wrap.uid)").parse { response in
            wrap.remove()
            return nil
            }.contributionUnavailable(wrap)
    }
    
    class func leaveWrap(wrap: Wrap) -> Self {
        return DELETE().path("wraps/\(wrap.uid)/leave").parse { response in
            if wrap.isPublic {
                if let user = User.currentUser {
                    wrap.contributors.remove(user)
                    wrap.notifyOnUpdate(.ContributorsChanged)
                }
            } else {
                wrap.remove()
            }
            return nil
            }.contributionUnavailable(wrap)
    }
    
    class func followWrap(wrap: Wrap) -> Self {
        return POST().path("wraps/\(wrap.uid)/follow").parse { response in
            wrap.touch()
            if let user = User.currentUser {
                wrap.contributors.insert(user)
                wrap.notifyOnUpdate(.ContributorsChanged)
            }
            PubNub.sharedInstance?.hereNowForChannel(wrap.uid, withVerbosity: .State) { (result, status) -> Void in
                if let uuids = result?.data?.uuids as? [[String:AnyObject]] {
                    var broadcasts = [LiveBroadcast]()
                    for uuid in uuids {
                        guard let state = uuid["state"] as? [String:AnyObject] else { continue }
                        guard let user = User.entry(state["userUid"] as? String) else { continue }
                        if let streamName = state["streamName"] as? String {
                            let broadcast = LiveBroadcast()
                            broadcast.broadcaster = user
                            broadcast.wrap = wrap
                            broadcast.title = state["title"] as? String
                            broadcast.streamName = streamName
                            broadcasts.append(broadcast)
                            user.fetchIfNeeded(nil, failure: nil)
                        }
                    }
                    if broadcasts.count > 0 {
                        wrap.liveBroadcasts = broadcasts
                        wrap.notifyOnUpdate(.LiveBroadcastsChanged)
                    }
                }
            }
            return wrap
            }.contributionUnavailable(wrap)
    }
    
    class func unfollowWrap(wrap: Wrap) -> Self {
        return DELETE().path("wraps/\(wrap.uid)/unfollow").parse { response in
            if let user = User.currentUser {
                wrap.contributors.remove(user)
                wrap.notifyOnUpdate(.ContributorsChanged)
            }
            if wrap.liveBroadcasts.count > 0 {
                wrap.liveBroadcasts = []
                wrap.notifyOnUpdate(.LiveBroadcastsChanged)
            }
            return nil
            }.contributionUnavailable(wrap)
    }
    
    class func postComment(comment: Comment) -> Self? {
        guard let candy = comment.candy else { return nil }
        guard let wrap = candy.wrap else { return nil }
        return POST().path("wraps/\(wrap.uid)/candies/\(candy.uid)/comments").parametrize({ (request) -> Void in
            request["message"] = comment.text
            request["upload_uid"] = comment.locuid
            request["contributed_at_in_epoch"] = NSNumber(double: comment.updatedAt.timestamp)
        }).parse { response in
            if let dictionary = response.dictionary("comment") where candy.valid {
                comment.map(dictionary, container: candy)
                candy.touch(comment.createdAt)
                if let commentCount = response.data["comment_count"] as? Int where candy.commentCount < Int16(commentCount) {
                    candy.commentCount = Int16(commentCount)
                }
                return comment;
            } else {
                return nil
            }
            }.contributionUnavailable(candy)
    }
    
    class func resendConfirmation(email: String?) -> Self {
        return POST().path("users/resend_confirmation").parametrize({ $0["email"] = email })
    }
    
    class func resendInvite(wrap: Wrap, user: User) -> Self {
        return POST().path("wraps/\(wrap.uid)/resend_invitation").parametrize({ $0["user_uid"] = user.uid })
    }
    
    class func user(user: User) -> Self? {
        return GET().path("users/\(user.uid)").parse({ (response) -> AnyObject? in
            if let dictionary = response.dictionary("user") {
                user.map(dictionary)
                user.notifyOnUpdate(.Default)
            }
            return user
        })
    }
    
    class func preferences(wrap: Wrap) -> Self {
        return GET().path("wraps/\(wrap.uid)/preferences").parse { response in
            if let _wrap = wrap.validEntry() {
                if let preference = response.dictionary("wrap_preference") {
                    _wrap.isCandyNotifiable = preference["notify_when_image_candy_addition"] as? Bool ?? false
                    _wrap.isChatNotifiable = preference["notify_when_chat_addition"] as? Bool ?? false
                    _wrap.notifyOnUpdate(.PreferencesChanged)
                }
                return _wrap
            } else {
                return nil
            }
            }.contributionUnavailable(wrap)
    }
    
    class func changePreferences(wrap: Wrap) -> Self {
        return PUT().path("wraps/\(wrap.uid)/preferences").parametrize({
            $0["notify_when_image_candy_addition"] = wrap.isCandyNotifiable
            $0["notify_when_chat_addition"] = wrap.isChatNotifiable
        }).parse({ (_) -> AnyObject? in
            return wrap.validEntry()
        }).contributionUnavailable(wrap)
    }
    
    class func verificationCall() -> Self {
        return POST().path("users/call").parametrize({
            $0["email"] = Authorization.currentAuthorization.email
            $0["device_uid"] = Authorization.currentAuthorization.deviceUID
        })
    }
    
    class func uploadMessage(message: Message) -> Self? {
        guard let wrap = message.wrap else { return nil }
        return POST().path("wraps/\(wrap.uid)/chats").parametrize({ (request) -> Void in
            request["message"] = message.text
            request["upload_uid"] = message.locuid
        }).parse { response in
            if let dictionary = response.dictionary("chat") where wrap.valid {
                message.map(dictionary)
                message.notifyOnUpdate(.ContentAdded)
                return message
            } else {
                return nil
            }
            }.contributionUnavailable(wrap)
    }
    
    private func parseContributors(wrap: Wrap) -> Self {
        return parse { response in
            if let _wrap = wrap.validEntry(), let array = response.array("contributors") {
                let contributors = Set(User.mappedEntries(User.prefetchArray(array))) as! Set<User>
                if _wrap.contributors != contributors {
                    _wrap.contributors = contributors
                    _wrap.notifyOnUpdate(.ContributorsChanged)
                }
                return _wrap
            } else {
                return nil
            }
        }
    }
    
    class func contributors(wrap: Wrap) -> Self {
        return GET().path("wraps/\(wrap.uid)/contributors").parseContributors(wrap).contributionUnavailable(wrap)
    }
    
    class func addContributors(contributors: Set<AddressBookPhoneNumber>, wrap: Wrap, message: String?) -> Self? {
        return POST().path("wraps/\(wrap.uid)/add_contributor").parametrize({ (request) -> Void in
            
            let registeredContributors = contributors.filter({ $0.user != nil })
            request["user_uids"] = registeredContributors.map({ $0.user!.uid })
            request["message"] = message
            
            var unregisteredContributors = contributors.subtract(registeredContributors)
            var invitees = [[String : AnyObject]]()
            while !unregisteredContributors.isEmpty {
                if let phoneNumber = unregisteredContributors.first {
                    if let record = phoneNumber.record {
                        let groupedContributors = unregisteredContributors.filter({ $0.record == record })
                        let phoneNumbers: [String] = groupedContributors.map({ $0.phone ?? "" })
                        invitees.append(["name":phoneNumber.name ?? "","phone_numbers" : phoneNumbers])
                        unregisteredContributors.subtractInPlace(groupedContributors)
                    } else {
                        invitees.append(["name":phoneNumber.name ?? "","phone_number" : phoneNumber.phone ?? ""])
                        unregisteredContributors.remove(phoneNumber)
                    }
                }
            }
            let _invitees: [String] = invitees.map({ String(data: try! NSJSONSerialization.dataWithJSONObject($0, options: []), encoding: NSUTF8StringEncoding) ?? "" })
            request["invitees"] = _invitees
        }).parseContributors(wrap).contributionUnavailable(wrap)
    }
    
    class func removeContributors(contributors: [User], wrap: Wrap) -> Self? {
        return DELETE().path("wraps/\(wrap.uid)/remove_contributor").parametrize({
            $0["user_uids"] = contributors.map({ $0.uid })
        }).parseContributors(wrap).contributionUnavailable(wrap)
    }
    
    class func uploadWrap(wrap: Wrap) -> Self {
        return POST().path("wraps").parametrize({ (request) -> Void in
            request["name"] = wrap.name
            request["upload_uid"] = wrap.locuid
            request["contributed_at_in_epoch"] = NSNumber(double: wrap.updatedAt.timestamp)
        }).parse({ (response) -> AnyObject? in
            if let wrap = wrap.validEntry() {
                if let dictionary = response.dictionary("wrap") {
                    wrap.map(dictionary)
                    wrap.notifyOnAddition()
                }
                return wrap
            } else {
                return nil
            }
        })
    }
    
    class func updateUser(user: User, email: String?) -> Self {
        return PUT().path("users/update").file({ _ in user.avatar?.large }).parametrize({
            $0["name"] = user.name
            $0["email"] = email
        }).parse({ (response) -> AnyObject? in
            if let userData = response.dictionary("user") {
                let authorization = Authorization.currentAuthorization
                authorization.updateWithUserData(userData)
                user.map(userData)
                User.currentUser = user
                user.notifyOnUpdate(.Default)
            }
            return user
        })
    }
    
    class func updateWrap(wrap: Wrap) -> Self {
        return PUT().path("wraps/\(wrap.uid)").parametrize({ (request) -> Void in
            request["name"] = wrap.name
            request["is_restricted_invite"] = wrap.isRestrictedInvite
        }).parse({ (response) -> AnyObject? in
            if let wrap = wrap.validEntry() {
                if let dictionary = response.dictionary("wrap") {
                    wrap.map(dictionary)
                    wrap.notifyOnUpdate(.Default)
                }
                return wrap
            } else {
                return nil
            }
        })
    }
    
    class func reportCandy(candy: Candy, violation: Violation) -> Self? {
        guard let wrap = candy.wrap else { return nil }
        return POST().path("wraps/\(wrap.uid)/candies/\(candy.uid)/violations").parametrize({
            $0["violation_code"] = violation.code
        })
    }
    
    class func contributorsFromRecords(records: [AddressBookRecord]) -> Self? {
        return POST().path("users/sign_up_status").parametrize({ request in
            var phones = [String]()
            for record in records {
                for phoneNumber in record.phoneNumbers {
                    phones.append(phoneNumber.phone)
                }
            }
            request["phone_numbers"] = phones
        }).parse({ (response) -> AnyObject? in
            if let array = response.array("users") {
                
                var users = [String : [String : AnyObject]]()
                for user in array {
                    if let number = user["address_book_number"] as? String {
                        users[number] = user
                    }
                }
                
                var registeredUsers = Set<User>()
                
                var contributors = [AddressBookRecord]()
                for record in records {
                    var phoneNumbers = [AddressBookPhoneNumber]()
                    for phoneNumber in record.phoneNumbers {
                        if let userData = users[phoneNumber.phone] {
                            if let user = User.mappedEntry(userData) {
                                if user.current || registeredUsers.contains(user) {
                                    break
                                }
                                registeredUsers.insert(user)
                                phoneNumber.user = user
                                phoneNumber.activated = userData["sign_in_count"] as? Int > 0
                            }
                        }
                        phoneNumbers.append(phoneNumber)
                    }
                    
                    if !phoneNumbers.isEmpty {
                        record.phoneNumbers = phoneNumbers
                        contributors.append(record)
                    }
                }
                return contributors
            } else {
                return records
            }
        })
    }
}