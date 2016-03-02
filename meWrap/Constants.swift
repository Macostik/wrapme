//
//  Constants.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class Constants: NSObject {
    static let pixelSize: CGFloat = 1.0
    static let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
    static let isPhone: Bool = UI_USER_INTERFACE_IDIOM() == .Phone
    static let appStoreID: Int = 879908578
    static let albumName = "meWrap"
    static let maxVideoRecordedDuration: NSTimeInterval = 60
    static let addressBookPhoneNumberMinimumLength = 6
    static let profileNameLimit = 40
    static let phoneNumberLimit = 20
    static let wrapNameLimit = 190
    static let recentCandiesLimit = 6
    static let recentCandiesLimit_2 = 3
    static let composeBarDefaultCharactersLimit: CGFloat = 21000
    static let encryptedAuthorization = "encrypted_authorization"
    static let groupIdentifier = "group.com.ravenpod.wraplive"
}

typealias Block = Void -> Void
typealias ObjectBlock = AnyObject? -> Void
typealias FailureBlock = NSError? -> Void
typealias BooleanBlock = Bool -> Void