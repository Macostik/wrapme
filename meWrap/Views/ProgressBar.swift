//
//  ProgressBar+APIRequest.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ProgressBar: UIView {
    
    override class func layerClass() -> AnyClass { return CAShapeLayer.self }
    
    private var animation = CABasicAnimation(keyPath: "strokeEnd")
    
    @IBInspectable var lineWidth: CGFloat = 4
    
    var renderedSize: CGSize = CGSize.zero
    
    private var _progress: CGFloat = 0
    var progress: CGFloat {
        set {
            setProgress(newValue, animated: false)
        }
        get { return _progress }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        clipsToBounds = true
        guard let layer = layer as? CAShapeLayer else { return }
        layer.masksToBounds = true
        layer.rasterizationScale = UIScreen.mainScreen().scale
        layer.shouldRasterize = true
        layer.fillColor = UIColor.clearColor().CGColor
        layer.strokeColor = Color.orange.CGColor
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
        updatePath()
        layer.actions = ["strokeEnd":NSNull()]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePathIfNeeded()
    }
    
    private func updatePathIfNeeded() {
        if renderedSize != bounds.size {
            updatePath()
        }
    }
    
    private func updatePath() {
        guard let layer = layer as? CAShapeLayer else { return }
        let size = bounds.size
        let path = UIBezierPath()
        if size.width > size.height {
            layer.lineWidth = self.lineWidth > 0 ? self.lineWidth : 4
            path.move(0, size.height/2.0).line(size.width, size.height/2.0)
        } else {
            layer.lineWidth = 2;
            path.addArcWithCenter(CGPoint(x: size.width/2.0, y: size.height/2.0), radius: size.width/2 - 1, startAngle: -CGFloat(M_PI_2), endAngle: CGFloat(3*M_PI/2), clockwise: true)
        }
        layer.path = path.CGPath
        renderedSize = size
    }
    
    func setProgress(progress: CGFloat, animated: Bool) {
        let progress = max(0, min(1, progress))
        if (_progress != progress) {
            _progress = progress;
            updateProgress(animated)
        }
    }
    
    private static let animationKey = "strokeAnimation"
    
    func updateProgress(animated: Bool) {
        guard let layer = layer as? CAShapeLayer else { return }
        if animated {
            let fromValue = ((layer.presentationLayer() as? CAShapeLayer) ?? layer).strokeEnd ?? 0
            animation.duration = CFTimeInterval(abs(_progress - fromValue))
            animation.fromValue = fromValue
            animation.toValue = _progress
            layer.removeAnimationForKey(ProgressBar.animationKey)
            layer.strokeEnd = _progress
            layer.addAnimation(animation, forKey: ProgressBar.animationKey)
        } else {
            layer.removeAnimationForKey(ProgressBar.animationKey)
            layer.strokeEnd = _progress
        }
    }
}

extension ProgressBar {
    func uploadProgress() -> NSProgress -> Void {
        return { [weak self] progress in
            let completed = CGFloat(progress.completedUnitCount)
            let total = CGFloat(progress.totalUnitCount)
            let value = 0.45 * completed/total
            self?.setProgress(0.1 + value, animated: true)
        }
    }
    
    func downloadProgress() -> NSProgress -> Void {
        return { [weak self] progress in
            let completed = CGFloat(progress.completedUnitCount)
            let total = CGFloat(progress.totalUnitCount)
            let value = 0.45 + 0.45 * completed/total
            self?.setProgress(0.1 + value, animated: true)
        }
    }
}

extension APIRequest {
    
    func handleProgress(progressBar: ProgressBar) -> APIRequest {
        uploadProgress = progressBar.uploadProgress()
        downloadProgress = progressBar.downloadProgress()
        return self
    }
}