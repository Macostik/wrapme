//
//  WKInterfaceController+SimplifiedTextInput.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/27/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import WatchKit
import Foundation

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

extension UIImage {
    class func loadWithURL(url: String, completion: UIImage -> Void) {
        if let image = InMemoryImageCache.instance[url] {
            completion(image)
        } else {
            guard let _url = NSURL(string: url) else { return }
            let request = NSURLRequest(URL: _url)
            let task = NSURLSession.sharedSession().downloadTaskWithRequest(request, completionHandler: { (outputURL, response, error) -> Void in
                guard let _url = outputURL else { return }
                guard let data = NSData(contentsOfURL: _url) else { return }
                guard let image = UIImage(data: data) else { return }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    InMemoryImageCache.instance[url] = image
                    completion(image)
                    })
            })
            task.resume()
        }
    }
}

extension WKInterfaceImage {
    
    func setURL(url: String?) {
        if let url = url where !url.isEmpty {
            UIImage.loadWithURL(url) { [weak self] (image) -> Void in
                self?.setImage(image)
            }
        }
    }
}

extension WKInterfaceGroup {
    
    func setURL(url: String?) {
        if let url = url where !url.isEmpty {
            UIImage.loadWithURL(url) { [weak self] (image) -> Void in
                self?.setBackgroundImage(image)
                }
        }
    }
}