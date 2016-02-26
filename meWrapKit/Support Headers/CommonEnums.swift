//
//  CommonEnums.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/1/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

@objc enum Event: Int16 {
    case Add, Update, Delete
}

enum ContributionStatus: Int {
    case Ready, InProgress, Finished
}

@objc enum MediaType: Int16 {
    case Photo = 10, Video = 20
}