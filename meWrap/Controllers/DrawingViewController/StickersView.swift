//
//  StickersView.swift
//  meWrap
//
//  Created by Yura Granchenko on 07/04/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class StickersView: UIView {
    
    lazy var contentView: UIView = specify(UIView()) { view in
        view.backgroundColor = UIColor.clearColor()
    }
    
    var transformView = TransformView()
    var isRotate = false
    var isChangeBounds = false
    var isMove = false
    weak var emojiView: FullScreenEmojiView?
    var close: (Sticker? -> Void)?
    
    class func show(view: UIView, canvas: DrawingCanvas, close: (Sticker? -> Void)) {
        let stickerView = StickersView(frame: view.bounds)
        view.add(stickerView)
        stickerView.close = close
        stickerView.setup(canvas)
    }
    
    func setup(canvas: DrawingCanvas) {
        
        add(contentView) { (make) in
            make.edges.equalTo(canvas)
        }
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.finish(_:))))
        
        transformView.trashLabel.addTarget(self, action: #selector(self.remove(_:)), forControlEvents: .TouchUpInside)
        let scalingGesture = UIPanGestureRecognizer(target: self, action: #selector(self.scaling(_:)))
        transformView.scaleLabel.addGestureRecognizer(scalingGesture)
        let rotatingGesture = UIPanGestureRecognizer(target: self, action: #selector(self.rotating(_:)))
        transformView.rotateLabel.addGestureRecognizer(rotatingGesture)
        
        let panningGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panning(_:)))
        transformView.addGestureRecognizer(panningGesture)
        panningGesture.requireGestureRecognizerToFail(scalingGesture)
        panningGesture.requireGestureRecognizerToFail(rotatingGesture)
        
        emojiView = FullScreenEmojiView.show(selectedBlock: { [weak self] emoji in
            self?.emojiSelected(emoji)
            }, close: { [weak self] in
                self?.removeFromSuperview()
                self?.close?(nil)
        })
    }
    
    func remove(sender: AnyObject) {
        removeFromSuperview()
        close?(nil)
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(transformView)
        let transform = transformView.transform
        transformView.transform = CGAffineTransformTranslate(transform, translation.x, translation.y)
        sender.setTranslation(CGPoint.zero, inView: transformView)
    }
    
    func scaling(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(transformView)
        let scale = abs(translation.x) > abs(translation.y) ? translation.x : translation.y
        transformView.fontSize += scale
        sender.setTranslation(CGPoint.zero, inView: transformView)
    }
    
    func rotating(sender: UIPanGestureRecognizer) {
        
        let p1 = contentView.convertPoint(transformView.rotateLabel.center, fromCoordinateSpace: transformView)
        let p2 = sender.locationInView(contentView)
        let center = contentView.convertPoint(transformView.emojiLabel.center, fromCoordinateSpace: transformView)
        let v1 = CGVector(dx: p1.x - center.x, dy: p1.y - center.y)
        let v2 = CGVector(dx: p2.x - center.x, dy: p2.y - center.y)
        
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        
        let transform = CGAffineTransformRotate(transformView.transform, angle)
        transformView.transform = transform
        sender.setTranslation(CGPoint.zero, inView: transformView)
    }
    
    func emojiSelected(emoji: String) {
        add(transformView) {
            $0.leading.top.equalTo(contentView)
        }
        transformView.emojiLabel.text = emoji
        transformView.layoutIfNeeded()
        transformView.transform = CGAffineTransformMakeTranslation(contentView.width/2 - transformView.width/2, contentView.height/2 - transformView.height/2)
        transformView.fontSize = min(contentView.width, contentView.height) / 3
    }
    
    @objc private func finish(sender: UITapGestureRecognizer) {
        let sticker = Sticker(transformView: transformView)
        close?(sticker)
        self.removeFromSuperview()
    }
    
}

class TransformView: UIView {
    
    let trashLabel = specify(Button(icon: "n", size: 20)) {
        $0.highlightedColor = Color.orangeDark
        $0.backgroundColor = Color.orange
        $0.cornerRadius = 20
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
    }
    
    let rotateLabel = specify(Button(icon: "5", size: 20)) {
        $0.backgroundColor = Color.orange
        $0.cornerRadius = 20
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
    }
    
    let scaleLabel = specify(Button(icon: "v", size: 20)) {
        $0.backgroundColor = Color.orange
        $0.cornerRadius = 20
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
        $0.transform = CGAffineTransformMakeRotation(-37)
    }
    
    var emojiLabel = specify(UILabel() , {
        $0.text = ""
        $0.backgroundColor = UIColor.clearColor()
        $0.textAlignment = .Center
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1.0
        $0.font = UIFont.systemFontOfSize(150)
    })
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.add(emojiLabel, {
            $0.edges.equalTo(self).inset(20)
            $0.width.equalTo(emojiLabel.snp_height)
        })
        self.add(trashLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(emojiLabel.snp_trailing)
            $0.centerY.equalTo(emojiLabel.snp_top)
        })
        self.add(rotateLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(emojiLabel.snp_leading)
            $0.centerY.equalTo(emojiLabel.snp_top)
        })
        self.add(scaleLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(emojiLabel.snp_trailing)
            $0.centerY.equalTo(emojiLabel.snp_bottom)
        })
    }
    
    var fontSize: CGFloat {
        get {
            return emojiLabel.font.pointSize
        }
        set {
            emojiLabel.font = UIFont.systemFontOfSize(max(40, round(newValue)))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Sticker: Drawing {
    
    let name: String
    let font: UIFont
    let transform: CGAffineTransform
    private let drawRect: CGRect
    private let attributes: [String : AnyObject]
    
    init(transformView: TransformView) {
        name = transformView.emojiLabel.text ?? ""
        font = transformView.emojiLabel.font
        transform = transformView.transform
        attributes = [NSFontAttributeName: font]
        let size = (name as NSString).sizeWithAttributes(attributes)
        let labelSize = transformView.emojiLabel.size
        let dx = labelSize.width - size.width
        let dy = labelSize.height - size.height
        drawRect = CGRect(origin: (20 + dx/2) ^ (20 - dy/2), size: size)
    }
    
    func render() {
        let rect = drawRect
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, rect.midX, rect.midY)
        CGContextConcatCTM(context, transform)
        CGContextTranslateCTM(context, -rect.midX, -rect.midY)
        (name as NSString).drawInRect(rect, withAttributes: attributes)
        CGContextRestoreGState(context)
    }
}
