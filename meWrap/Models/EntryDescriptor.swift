//
//  EntryDesriptor.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class EntryDescriptor: NSObject {
    var uid: String?
    var locuid: String?
    var name: String?
}

extension EntryContext {
    func fetchEntries(descriptors: [EntryDescriptor]) {
        
    }
}
