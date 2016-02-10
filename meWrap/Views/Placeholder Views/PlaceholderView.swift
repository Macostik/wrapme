//
//  PlaceholderView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class PlaceholderLoaderController: UIViewController {
    @IBOutlet var placeholderView: PlaceholderView!
}

class PlaceholderLoader: StreamLoader {
    
    static let storyboard = UIStoryboard(name: "Placeholders", bundle: nil)
    
    override func loadView(metrics: StreamMetrics) -> StreamReusableView? {
        if let identifier = identifier {
            let controller = PlaceholderLoader.storyboard.instantiateViewControllerWithIdentifier(identifier) as? PlaceholderLoaderController
            return controller?.placeholderView
        } else {
            return nil
        }
    }
}

class PlaceholderView: StreamReusableView {
    
    @IBOutlet weak var textLabel: UILabel?
    
    var actionBlock: (Void -> Void)?
    
    @IBAction func action(sender: AnyObject) {
        actionBlock?()
    }
}