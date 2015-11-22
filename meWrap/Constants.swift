//
//  Constants.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class Constants: NSObject {
    let pixelSize: CGFloat = 1.0 / (UIScreen.mainScreen().scale < 2 ? UIScreen.mainScreen().scale : 2)
    let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
    let isPhone: Bool = UI_USER_INTERFACE_IDIOM() == .Phone
    let appStoreID: Int = 879908578
    let albumName = "meWrap"
    let maxVideoRecordedDuration: NSTimeInterval = 60
    let addressBookPhoneNumberMinimumLength = 6
    let profileNameLimit = 40
    let phoneNumberLimit = 20
    let wrapNameLimit = 190
    let homeTopWrapCandiesLimit = 6
    let homeTopWrapCandiesLimit_2 = 3
    let composeBarDefaultCharactersLimit: CGFloat = 21000
    let encryptedAuthorization = "encrypted_authorization"
    let groupIdentifier = "group.com.ravenpod.wraplive"
}