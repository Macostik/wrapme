//
//  OverlayImageView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/24/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class OverlayImageView: WLImageView {
    
    weak var overlay: UIImageView?
    
    @IBInspectable var overlayColor = UIColor.whiteColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let overlay = UIImageView()
        overlay.backgroundColor = UIColor.clearColor()
        updateOverlay()
        addSubview(overlay)
        self.overlay = overlay
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateOverlay()
    }
    
    private static var overlayImages: [String: UIImage] = {
        var overlayImages = [String: UIImage]()
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { (_) -> Void in
            overlayImages.removeAll()
        })
        return overlayImages
    }()
    
    func overlayIdentifier() -> String {
        return "Circle"
    }
    
    func updateOverlay() {
        if let overlay = overlay {
            overlay.frame = bounds
            overlay.image = overlayImage()
        }
    }
    
    private func overlayImage() -> UIImage {
        let overlayKey = "\(overlayIdentifier())\(NSStringFromCGSize(size))"
        if let overlay = OverlayImageView.overlayImages[overlayKey] {
            return overlay
        } else {
            let overlay = UIImage.draw(size, drawing: { (size) -> Void in
                self.drawOverlayImageInRect(self.bounds)
            })
            OverlayImageView.overlayImages[overlayKey] = overlay
            return overlay
        }
    }
    
    func drawOverlayImageInRect(rect: CGRect) {
        overlayColor.setFill()
        UIBezierPath(rect: rect).fill()
        UIBezierPath(ovalInRect: rect).fillWithBlendMode(.Clear, alpha: 0)
    }
}