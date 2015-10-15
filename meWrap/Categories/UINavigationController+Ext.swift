//
//  UINavigationController+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/15/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UINavigationController {
    public override func shouldAutorotate() -> Bool {
        return true
    }
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        guard let topViewController = topViewController else {
            return super.supportedInterfaceOrientations()
        }
        return topViewController.supportedInterfaceOrientations()
    }
}