//
//  APIRequestDefined.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/18/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import PubNub
import Alamofire

extension APIRequest {
    func contributionUnavailable(contribution: Contribution) -> Self {
        beforeFailure = {
            if contribution.uploaded && ($0?.isResponseError(.ContentUnavailable) ?? false) {
                contribution.remove()
            }
        }
        return self
    }
    
    func configureForInvitation(wrap: Wrap) {
        guard let invitees = wrap.invitees else { return }
        let registeredContributors = invitees.filter({ $0.user != nil })
        self["user_uids"] = registeredContributors.map({ $0.user!.uid })
        self["message"] = wrap.invitationMessage
        
        let unregisteredContributors = invitees.subtract(registeredContributors)
        var inviteByPhone = [[String : AnyObject]]()
        
        for invitee in unregisteredContributors {
            if let phones = invitee.phone?.characters.split(",").map({ String($0) }) where phones.count > 0 {
                if phones.count > 1 {
                    inviteByPhone.append(["name":invitee.name ?? "","phone_numbers" : phones])
                } else {
                    inviteByPhone.append(["name":invitee.name ?? "","phone_number" : phones[0]])
                }
            }
        }
        self["invitees"] = inviteByPhone.map({ String(data: try! NSJSONSerialization.dataWithJSONObject($0, options: []), encoding: NSUTF8StringEncoding) ?? "" })
    }
}

struct API {
    
    static var manager = API.createManager()
    
    static let headers = [
        "Accept": "application/vnd.ravenpod+json;version=\(Environment.current.version)",
        "Accept-Encoding": "gzip"
    ]
    
    static func cancelAll() {
        manager = createManager()
    }
    
    private static func createManager() -> Alamofire.Manager {
        let manager = Alamofire.Manager()
        manager.startRequestsImmediately = true
        manager.session.configuration.timeoutIntervalForRequest = 45
        return manager
    }
}

extension API {
    
    static func wraps(scope: String?) -> PaginatedRequest<[Wrap]> {
        return PaginatedRequest<[Wrap]>(.GET, "wraps", modifier: { $0["scope"] = scope }, parser: { response in
            if let wraps = response.array("wraps") {
                return mappedEntries(Wrap.prefetchArray(wraps))
            } else {
                return []
            }
        })
    }
    
    static func candies(wrap: Wrap) -> PaginatedRequest<[Candy]> {
        return PaginatedRequest<[Candy]>(.GET, modifier: { (request) -> Void in
            request.path = "wraps/\(wrap.uid)/candies"
            if let request = request as? PaginatedRequest {
                switch request.type {
                case .Newer:
                    request["offset_x_in_epoch"] = request.newer?.timestamp
                case .Older:
                    request["offset_y_in_epoch"] = wrap.candiesPaginationDate?.timestamp
                default: break
                }
            }
            }, parser: { response in
                if let candies = response.array("candies") where wrap.valid {
                    let candies: [Candy] = mappedEntries(Candy.prefetchArray(candies), container: wrap)
                    if let candiesPaginationDate = candies.last?.createdAt {
                        wrap.candiesPaginationDate = candiesPaginationDate
                    }
                    return candies
                } else {
                    return []
                }
        }).contributionUnavailable(wrap)
    }
    
    static func messages(wrap: Wrap) -> PaginatedRequest<[Message]> {
        return PaginatedRequest<[Message]>(.GET, "wraps/\(wrap.uid)/chats", parser: { response in
            if let chats = response.array("chats") where wrap.valid && !chats.isEmpty {
                let messages: [Message] = mappedEntries(Message.prefetchArray(chats), container: wrap)
                wrap.notifyOnUpdate(.ContentAdded)
                return messages
            } else {
                return []
            }
        }).contributionUnavailable(wrap)
    }
    
    static func wrap(wrap: Wrap, contentType: String?) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.GET, "wraps/\(wrap.uid)", modifier: { $0["pick"] = contentType }, parser: { response in
            if let dictionary = response.dictionary("wrap") where wrap.valid {
                return wrap.update(Wrap.prefetchDictionary(dictionary))
            } else {
                return wrap
            }
        }).contributionUnavailable(wrap)
    }
    
    static func candy(candy: Candy) -> APIRequest<Candy> {
        var path: String!
        if let wrap = candy.wrap {
            path = "wraps/\(wrap.uid)/candies/\(candy.uid)"
        } else {
            path = "entities/\(candy.uid)"
        }
        return APIRequest<Candy>(.GET, path, parser: { response in
            if let dictionary = response.dictionary("candy") {
                return candy.validEntry()?.update(Candy.prefetchDictionary(dictionary))
            } else {
                return candy
            }
        }).contributionUnavailable(candy)
    }
    
    static func candyPlaceholder(candy: Candy) -> APIRequest<Candy>? {
        guard let wrap = candy.wrap else { return nil }
        let path = "wraps/\(wrap.uid)/candies/placeholder"
        return APIRequest(.POST, path, modifier: {
            $0["upload_uid"] = candy.locuid
            $0["contributed_at"] = candy.createdAt.timestamp
            if let comment = candy.comments.first {
                $0["message"] = comment.text
                $0["message_upload_uid"] = comment.locuid
                $0["message_contributed_at"] = comment.createdAt.timestamp
            }
            }, parser: { response in
                if let candyObject = response.dictionary("candy") {
                    candy.map(candyObject, container: wrap)
                }
                return candy
        })
    }
    
    static func message(message: Message) -> APIRequest<Message> {
        return APIRequest(.GET, "entities/\(message.uid)", parser: { response in
            if let dictionary = response.dictionary("chat") {
                return message.validEntry()?.update(Message.prefetchDictionary(dictionary))
            } else {
                return message
            }
        }).contributionUnavailable(message)
    }
    
    static func commentPlaceholder(comment: Comment, candy: Candy, wrap: Wrap) -> APIRequest<Comment> {
        let path = "wraps/\(wrap.uid)/candies/\(candy.uid)/comments/placeholder"
        return APIRequest(.POST, path, modifier: {
            $0["upload_uid"] = comment.locuid
            $0["contributed_at"] = comment.createdAt.timestamp
            $0["message"] = comment.text
            }, parser: { response in
                if let commentObject = response.dictionary("comment") {
                    comment.map(commentObject, container: candy)
                }
                return comment
        })
    }
    
    static func comment(comment: Comment) -> APIRequest<Comment> {
        return APIRequest(.GET, "entities/\(comment.uid)", parser: { response in
            if let dictionary = response.dictionary("comment") {
                return comment.validEntry()?.update(Comment.prefetchDictionary(dictionary))
            } else {
                return comment
            }
        }).contributionUnavailable(comment)
    }
    
    static func deleteCandy(candy: Candy) -> APIRequest<Response>? {
        guard let wrap = candy.wrap else { return nil }
        return APIRequest(.DELETE, "wraps/\(wrap.uid)/candies/\(candy.uid)", parser: { response in
            candy.remove()
            return response
        }).contributionUnavailable(candy)
    }
    
    static func deleteComment(comment: Comment, candy: Candy, wrap: Wrap) -> APIRequest<Response> {
        return APIRequest(.DELETE, "wraps/\(wrap.uid)/candies/\(candy.uid)/comments/\(comment.uid)", parser: { response in
            comment.remove()
            candy.validEntry()?.commentCount = Int16(response.data["comment_count"] as? Int ?? 0)
            return response
        }).contributionUnavailable(comment)
    }
    
    static func deleteWrap(wrap: Wrap) -> APIRequest<Response> {
        return APIRequest(.DELETE, "wraps/\(wrap.uid)", parser: { response in
            wrap.remove()
            return response
        }).contributionUnavailable(wrap)
    }
    
    static func leaveWrap(wrap: Wrap) -> APIRequest<Response> {
        return APIRequest(.DELETE, "wraps/\(wrap.uid)/leave", parser: { response in
            wrap.remove()
            return response
        }).contributionUnavailable(wrap)
    }
    
    static func postComment(comment: Comment, candy: Candy, wrap: Wrap) -> APIRequest<Comment> {
        return APIRequest(.POST, "wraps/\(wrap.uid)/candies/\(candy.uid)/comments", modifier: {
            $0["message"] = comment.text
            $0["upload_uid"] = comment.locuid
            $0["contributed_at_in_epoch"] = NSNumber(double: comment.updatedAt.timestamp)
            }, parser: { response in
                if let dictionary = response.dictionary("comment") where candy.valid {
                    comment.map(dictionary, container: candy)
                    candy.touch(comment.createdAt)
                    if let commentCount = response.data["comment_count"] as? Int where candy.commentCount < Int16(commentCount) {
                        candy.commentCount = Int16(commentCount)
                    }
                }
                return comment
        }).contributionUnavailable(candy)
    }
    
    static func resendConfirmation(email: String?) -> APIRequest<Response> {
        return APIRequest(.POST, "users/resend_confirmation", modifier: { $0["email"] = email }, parser: { $0 })
    }
    
    static func resendInvite(wrap: Wrap, user: User) -> APIRequest<Response> {
        return APIRequest(.POST, "wraps/\(wrap.uid)/resend_invitation", modifier: { $0["user_uid"] = user.uid }, parser: { $0 })
    }
    
    static func user(user: User) -> APIRequest<User> {
        return APIRequest<User>(.GET, "users/\(user.uid)", parser: { response in
            if let dictionary = response.dictionary("user") {
                user.map(dictionary)
                user.notifyOnUpdate(.Default)
            }
            return user
        })
    }
    
    static func preferences(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.GET, "wraps/\(wrap.uid)/preferences", parser: { response in
            if let preference = response.dictionary("wrap_preference") {
                wrap.isCandyNotifiable = preference["notify_when_image_candy_addition"] as? Bool ?? false
                wrap.isChatNotifiable = preference["notify_when_chat_addition"] as? Bool ?? false
                wrap.isCommentNotifiable = preference["notify_when_comment_addition"] as? Bool ?? false
                wrap.notifyOnUpdate(.PreferencesChanged)
            }
            return wrap
        }).contributionUnavailable(wrap)
    }
    
    static func changePreferences(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.PUT, "wraps/\(wrap.uid)/preferences", modifier: {
            $0["notify_when_image_candy_addition"] = wrap.isCandyNotifiable
            $0["notify_when_chat_addition"] = wrap.isChatNotifiable
            $0["notify_when_comment_addition"] = wrap.isCommentNotifiable
            }, parser: { _ in
                return wrap.validEntry()
        }).contributionUnavailable(wrap)
    }
    
    static func verificationCall() -> APIRequest<Response> {
        return APIRequest(.POST, "users/call", modifier: {
            $0["email"] = Authorization.current.email
            $0["device_uid"] = Authorization.current.deviceUID
            }, parser: { $0 })
    }
    
    static func uploadMessage(message: Message) -> APIRequest<Message>? {
        guard let wrap = message.wrap else { return nil }
        return APIRequest<Message>(.POST, "wraps/\(wrap.uid)/chats", modifier: { (request) -> Void in
            request["message"] = message.text
            request["upload_uid"] = message.locuid
            }, parser: { response in
                if let dictionary = response.dictionary("chat") where wrap.valid {
                    message.map(dictionary)
                    message.notifyOnUpdate(.ContentAdded)
                }
                return message
        }).contributionUnavailable(wrap)
    }
    
    private static func parseContributors(wrap: Wrap, response: Response) -> Wrap {
        if wrap.valid, let array = response.array("contributors") {
            let _contributors: [User] = mappedEntries(User.prefetchArray(array))
            let contributors = Set<User>(_contributors)
            if wrap.contributors != contributors {
                wrap.contributors = contributors
                wrap.notifyOnUpdate(.ContributorsChanged)
            }
        }
        return wrap
    }
    
    static func contributors(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.GET, "wraps/\(wrap.uid)/contributors", parser: { response in
            return self.parseContributors(wrap, response: response)
        }).contributionUnavailable(wrap)
    }
    
    static func addContributors(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.POST, "wraps/\(wrap.uid)/add_contributor", modifier: { (request) -> Void in
            request.configureForInvitation(wrap)
            }, parser: { response in
                wrap.invitees = nil
                wrap.invitationMessage = nil
                return self.parseContributors(wrap, response: response)
        }).contributionUnavailable(wrap)
    }
    
    static func removeContributors(contributors: [User], wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.DELETE, "wraps/\(wrap.uid)/remove_contributor", modifier: {
            $0["user_uids"] = contributors.map({ $0.uid })
            }, parser: { response in
                return self.parseContributors(wrap, response: response)
        }).contributionUnavailable(wrap)
    }
    
    static func uploadWrap(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.POST, "wraps", modifier: { (request) -> Void in
            request["name"] = wrap.name
            request["upload_uid"] = wrap.locuid
            request["contributed_at_in_epoch"] = NSNumber(double: wrap.updatedAt.timestamp)
            request.configureForInvitation(wrap)
            }, parser: { response in
                if wrap.valid {
                    if let dictionary = response.dictionary("wrap") {
                        wrap.map(dictionary)
                        wrap.notifyOnAddition()
                    }
                }
                return wrap
        })
    }
    
    static func updateUser(user: User, email: String?) -> APIRequest<User> {
        return APIRequest<User>(.PUT, "users/update", modifier: {
            $0["name"] = user.name
            $0["email"] = email
            $0.file = user.avatar?.large
            }, parser: { response in
                if let userData = response.dictionary("user") {
                    let authorization = Authorization.current
                    authorization.updateWithUserData(userData)
                    user.map(userData)
                    User.currentUser = user
                    user.notifyOnUpdate(.Default)
                }
                return user
        })
    }
    
    static func updateWrap(wrap: Wrap) -> APIRequest<Wrap> {
        return APIRequest<Wrap>(.PUT, "wraps/\(wrap.uid)", modifier: { (request) -> Void in
            request["name"] = wrap.name
            request["is_restricted_invite"] = wrap.isRestrictedInvite
            }, parser: { response in
                if wrap.valid {
                    if let dictionary = response.dictionary("wrap") {
                        wrap.map(dictionary)
                        wrap.notifyOnUpdate(.Default)
                    }
                }
                return wrap
        })
    }
    
    static func reportCandy(candy: Candy, violation: Violation) -> APIRequest<Response>? {
        guard let wrap = candy.wrap else { return nil }
        return APIRequest(.POST, "wraps/\(wrap.uid)/candies/\(candy.uid)/violations", modifier: {
            $0["violation_code"] = violation.code
            }, parser: { $0 })
    }
    
    static func contributorsFromRecords(records: [AddressBookRecord]) -> APIRequest<[AddressBookRecord]> {
        return APIRequest<[AddressBookRecord]>(.POST, "users/sign_up_status", modifier: { request in
            var phones = [String]()
            for record in records {
                for phoneNumber in record.phoneNumbers {
                    phones.append(phoneNumber.phone)
                }
            }
            request["phone_numbers"] = phones
            }, parser: { response in
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
                                if let user: User = mappedEntry(userData) {
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
    
    static func resetBadge() -> APIRequest<Response> {
        return APIRequest(.PUT, "devices/reset_badge", parser: { $0 })
    }
    
    static func deleteDevice(device: Device) -> APIRequest<Set<Device>> {
        return APIRequest(.DELETE, "devices/\(device.uid)", parser: { _ in
            let user = User.currentUser
            user?.devices.remove(device)
            return user?.devices ?? []
        })
    }
    
    static func devices() -> APIRequest<[Device]> {
        return APIRequest(.GET, "devices", parser: {
            let devices: [Device] = mappedEntries($0.array("devices"))
            User.currentUser?.devices = Set(devices)
            return devices
        })
    }
}