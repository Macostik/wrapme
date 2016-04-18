//
//  PaginatedRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/4/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum PaginatedRequestType: Int {
    case Fresh, Newer, Older
}

class PaginatedRequest: APIRequest {

    var type: PaginatedRequestType = .Fresh
    
    var newer: NSDate?
    
    var older: NSDate?
    
    required init(_ method: APIRequestMethod) {
        super.init(method)
        parametrize { (request) -> Void in
            if let request = request as? PaginatedRequest {
                switch request.type {
                case .Newer:
                    if let newer = request.newer {
                        request["offset_x_in_epoch"] = newer.timestamp
                    }
                    break
                case .Older:
                    if let newer = request.newer {
                        request["offset_x_in_epoch"] = newer.timestamp
                    }
                    if let older = request.older {
                        request["offset_y_in_epoch"] = older.timestamp
                    }
                    break
                default: break
                }
            }
        }
    }
    
    func fresh(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Fresh
        super.send(success, failure: failure)
    }

    func newer(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Newer
        super.send(success, failure: failure)
    }
    
    func older(success: ObjectBlock?, failure: FailureBlock?) {
        type = .Older
        super.send(success, failure: failure)
    }
}

extension PaginatedRequest {
    class func wraps(scope: String?) -> Self {
        return GET().path("wraps").parametrize({ (request) -> Void in
            if let scope = scope {
                request["scope"] = scope
            }
        }).parse({ (response) -> AnyObject! in
            if let wraps = response.array("wraps") {
                return Wrap.mappedEntries(Wrap.prefetchArray(wraps))
            } else {
                return []
            }
        })
    }
    
    class func candies(wrap: Wrap) -> Self {
        return GET().path({ "wraps/\(wrap.uid)/candies" }).forceParametrize({ (request) -> Void in
            if let request = request as? PaginatedRequest {
                switch request.type {
                case .Newer:
                    if let newer = request.newer {
                        request["offset_x_in_epoch"] = newer.timestamp
                    }
                    break
                case .Older:
                    if let older = wrap.candiesPaginationDate {
                        request["offset_y_in_epoch"] = older.timestamp
                    }
                    break
                default: break
                }
            }
        }).parse({ (response) -> AnyObject! in
            if let candies = response.array("candies") where wrap.valid {
                let candies = Candy.mappedEntries(Candy.prefetchArray(candies), container: wrap)
                if let candiesPaginationDate = candies.last?.createdAt {
                    wrap.candiesPaginationDate = candiesPaginationDate
                }
                return candies
            } else {
                return []
            }
        }).contributionUnavailable(wrap)
    }
    
    class func messages(wrap: Wrap) -> Self {
        return GET().path("wraps/%@/chats", wrap.uid).parse({ (response) -> AnyObject! in
            if let chats = response.array("chats") where wrap.valid && !chats.isEmpty {
                let messages = Message.mappedEntries(Message.prefetchArray(chats), container: wrap)
                wrap.notifyOnUpdate(.ContentAdded)
                return messages
            } else {
                return []
            }
        }).contributionUnavailable(wrap)
    }
}
