//
//  ImageView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/28/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class ImageView: UIImageView {
    
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
        contentMode = .ScaleAspectFill
        clipsToBounds = true
    }
    
    lazy var defaultIconView: UILabel = {
        let iconView = UILabel()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.hidden = true
        iconView.font = UIFont(name:"icons", size:self.defaultIconSize)
        iconView.textAlignment = .Center
        iconView.textColor = self.defaultIconColor
        iconView.backgroundColor = self.defaultBackgroundColor ?? self.backgroundColor
        iconView.text = self.defaultIconText
        self.insertSubview(iconView, atIndex: 0)
        iconView.snp_makeConstraints(closure: { $0.left.right.top.bottom.equalTo(self) })
        return iconView
    }()
    
    @IBInspectable var defaultIconSize: CGFloat = 24 {
        willSet { defaultIconView.font = UIFont(name:"icons", size:newValue) }
    }
    
    @IBInspectable var defaultIconText: String? {
        willSet { defaultIconView.text = newValue }
    }
    
    @IBInspectable var defaultIconColor = UIColor.whiteColor() {
        willSet { defaultIconView.textColor = newValue }
    }
    
    @IBInspectable var defaultBackgroundColor: UIColor? {
        willSet { defaultIconView.backgroundColor = newValue }
    }
    
    var url: String? {
        didSet {
            image = nil
            if let url = url where !url.isEmpty {
                defaultIconView.hidden = true
                ImageFetcher.defaultFetcher.enqueue(url, receiver: self)
            } else {
                defaultIconView.hidden = false
            }
        }
    }
    
    var success: ((image: UIImage?, cached: Bool) -> Void)?
    
    var failure: FailureBlock?
    
    func setURL(url: String?, success: ((image: UIImage?, cached: Bool) -> Void)?, failure: FailureBlock?) {
        self.success = success
        self.failure = failure
        self.url = url
    }
}

extension ImageView: ImageFetching {
    func fetcherTargetUrl(fetcher: ImageFetcher) -> String? {
        return url
    }
    func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError) {
        defaultIconView.hidden = false
        failure?(error)
        failure = nil
        success = nil
    }
    func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool) {
        defaultIconView.hidden = true
        self.image = image
        if !cached {
            addAnimation(CATransition.transition(kCATransitionFade))
        }
        success?(image: image, cached: cached)
        failure = nil
        success = nil
    }
}