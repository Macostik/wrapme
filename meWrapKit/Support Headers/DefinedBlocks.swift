//
//  DefinedBlocks.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/26/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

typealias Block = Void -> Void
typealias ObjectBlock = AnyObject? -> Void
typealias FailureBlock = NSError? -> Void
typealias BooleanBlock = Bool -> Void