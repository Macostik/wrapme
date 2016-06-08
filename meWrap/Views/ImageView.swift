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
    
    struct Placeholder {
        let text: String
        let size: CGFloat
        let backgroundColor: UIColor
        let textColor: UIColor
        static let gray = Placeholder(text: "&", size: 24, backgroundColor: Color.grayLighter, textColor: UIColor.whiteColor())
        static let white = Placeholder(text: "&", size: 24, backgroundColor: UIColor.whiteColor(), textColor: Color.grayLighter)
        func userStyle(size: CGFloat) -> Placeholder {
            return Placeholder(text: "&", size: size, backgroundColor: self.backgroundColor, textColor: self.textColor)
        }
        func photoStyle(size: CGFloat) -> Placeholder {
            return Placeholder(text: "t", size: size, backgroundColor: self.backgroundColor, textColor: self.textColor)
        }
    }
    
    convenience init(backgroundColor: UIColor, placeholder: Placeholder? = nil) {
        self.init()
        self.backgroundColor = backgroundColor
        contentMode = .ScaleAspectFill
        clipsToBounds = true
        if let placeholder = placeholder {
            applyPlaceholder(placeholder)
        }
    }
    
    lazy var placeholder: Label = {
        let iconView = Label(icon: "", size: 24, textColor: UIColor.whiteColor())
        iconView.hidden = true
        iconView.textAlignment = .Center
        iconView.backgroundColor = self.backgroundColor
        self.insertSubview(iconView, atIndex: 0)
        iconView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
        return iconView
    }()
    
    func applyPlaceholder(style: Placeholder) {
        placeholder.textColor = style.textColor
        placeholder.backgroundColor = style.backgroundColor
        placeholder.text = style.text
        placeholder.font = UIFont.icons(style.size)
    }
    
    weak var spinner: UIActivityIndicatorView?
    
    var url: String? {
        didSet {
            image = nil
            if let url = url where !url.isEmpty {
                placeholder.hidden = true
                spinner?.startAnimating()
                ImageFetcher.defaultFetcher.enqueue(url, receiver: self)
            } else {
                spinner?.stopAnimating()
                placeholder.hidden = false
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
        spinner?.stopAnimating()
        placeholder.hidden = false
        failure?(error)
        failure = nil
        success = nil
    }
    func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool) {
        spinner?.stopAnimating()
        placeholder.hidden = true
        self.image = image
        if !cached {
            addAnimation(CATransition.transition(kCATransitionFade))
        }
        success?(image: image, cached: cached)
        failure = nil
        success = nil
    }
}