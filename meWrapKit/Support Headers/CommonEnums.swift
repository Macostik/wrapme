//
//  CommonEnums.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/1/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

enum Event: Int16 {
    case Add, Update, Delete
}

enum ContributionStatus: Int {
    case Ready, InProgress, Finished
}

enum MediaType: Int16 {
    case Photo = 10, Video = 20
}