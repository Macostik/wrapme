//
//  WKInterfaceController+SimplifiedTextInput.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/27/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import WatchKit

extension WKInterfaceController {
    func presentTextSuggestionsFromPlistNamed(name: String, completionHandler: (String -> Void)) {
        guard let path = NSBundle.mainBundle().pathForResource(name, ofType: "plist") else {
            return
        }
        let presets = NSArray(contentsOfFile: path) as? [String]
        presentTextInputControllerWithSuggestions(presets, allowedInputMode: .AllowEmoji) { (results) -> Void in
            guard let results = results else {
                return
            }
            for result in results {
                if let result = result as? String {
                    completionHandler(result)
                    break
                }
            }
        }
    }
}