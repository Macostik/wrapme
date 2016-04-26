//
//  StickersView.swift
//  meWrap
//
//  Created by Yura Granchenko on 07/04/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

func ^(lhs: CGPoint, rhs: CGPoint) -> CGLine {
    return CGLine(start: lhs, end: rhs)
}

struct CGLine {
    
    let start: CGPoint
    let end: CGPoint
    
    var vertical: Bool { return start.x == end.x }
    
    func slope() -> CGFloat {
        return (start.y - end.y) / (start.x - end.x)
    }
    
    func angleBetween(line: CGLine) -> CGFloat {
        let slope1 = slope()
        let slope2 = line.slope()
        return atan((slope1 - slope2)/(1 + slope1 * slope2))
    }
    
    func distance() -> CGFloat {
        return start.distanceFrom(end)
    }
}

extension CGPoint {
    
    func distanceFrom(point: CGPoint) -> CGFloat {
        return hypot(x - point.x, y - point.y)
    }
    
    func angle(point: CGPoint, center: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: x - center.x, dy: y - center.y)
        let v2 = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        return atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
    }
}

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
        
        let cancelButton = Button(icon: "!", size: 24, textColor: UIColor.whiteColor())
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        add(cancelButton) { $0.leading.top.equalTo(self).inset(20) }
        
        let applyButton = Button(icon: "E", size: 24, textColor: UIColor.whiteColor())
        applyButton.addTarget(self, touchUpInside: #selector(self.apply(_:)))
        add(applyButton) { $0.trailing.top.equalTo(self).inset(20) }
        
        transformView.trashLabel.addTarget(self, action: #selector(self.cancel(_:)), forControlEvents: .TouchUpInside)
        let rotatingGesture = UIPanGestureRecognizer(target: self, action: #selector(self.rotating(_:)))
        transformView.rotateLabel.addGestureRecognizer(rotatingGesture)
        
        let panningGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panning(_:)))
        panningGesture.minimumNumberOfTouches = 1
        transformView.addGestureRecognizer(panningGesture)
        panningGesture.requireGestureRecognizerToFail(rotatingGesture)
        
        let multiplePanningGesture = UIPanGestureRecognizer(target: self, action: #selector(self.multiplePanning(_:)))
        multiplePanningGesture.minimumNumberOfTouches = 2
        transformView.addGestureRecognizer(multiplePanningGesture)
        
        emojiView = FullScreenEmojiView.show(selectedBlock: { [weak self] emoji in
            self?.emojiSelected(emoji)
            }, close: { [weak self] in
                self?.removeFromSuperview()
                self?.close?(nil)
        })
    }
    
    func panning(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(transformView)
        let transform = transformView.transform
        transformView.transform = CGAffineTransformTranslate(transform, translation.x, translation.y)
        sender.setTranslation(CGPoint.zero, inView: transformView)
    }
    
    func rotating(sender: UIPanGestureRecognizer) {
        
        let p1 = contentView.convertPoint(transformView.rotateLabel.center, fromCoordinateSpace: transformView)
        let p2 = sender.locationInView(contentView)
        
        let center = contentView.convertPoint(transformView.emojiLabel.center, fromCoordinateSpace: transformView)
        
        let d1 = p2.distanceFrom(center)
        let d2 = p1.distanceFrom(center)
        
        let angle = p1.angle(p2, center: center)
        
        transformView.transform = CGAffineTransformRotate(transformView.transform, angle)
        
        transformView.fontSize += d1 - d2
    }
    
    private var previousLine: CGLine?
    
    func multiplePanning(sender: UIPanGestureRecognizer) {
        
        if sender.state == .Ended || sender.state == .Cancelled {
            previousLine = nil
        } else {
            guard sender.numberOfTouches() > 1 else { return }
            let p1 = sender.locationOfTouch(0, inView: contentView)
            let p2 = sender.locationOfTouch(1, inView: contentView)
            let line: CGLine = p1 ^ p2
            if let previousLine = previousLine where !previousLine.vertical && !line.vertical {
                
                var transform = transformView.transform
                
                let angle = line.angleBetween(previousLine)
                transform = CGAffineTransformRotate(transform, angle)
                
                let translation = sender.translationInView(transformView)
                transform = CGAffineTransformTranslate(transform, translation.x, translation.y)
                sender.setTranslation(CGPoint.zero, inView: transformView)
                
                transformView.transform = transform
                
                let distance1 = previousLine.distance()
                let distance2 = line.distance()
                transformView.fontSize *= distance2/distance1
                self.previousLine = line
            } else {
                previousLine = line
            }
        }
    }
    
    func emojiSelected(emoji: String) {
        
        insertSubview(transformView, aboveSubview: contentView)
        transformView.snp_makeConstraints {
            $0.centerX.equalTo(contentView.snp_leading)
            $0.centerY.equalTo(contentView.snp_top)
        }
        transformView.emojiLabel.text = emoji
        transformView.transform = CGAffineTransformMakeTranslation(contentView.width/2, contentView.height/2)
        transformView.fontSize = min(contentView.width, contentView.height) / 3
    }
    
    @objc private func apply(sender: UITapGestureRecognizer) {
        let sticker = Sticker(transformView: transformView)
        close?(sticker)
        self.removeFromSuperview()
    }
    
    @objc private func cancel(sender: UITapGestureRecognizer) {
        removeFromSuperview()
        close?(nil)
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
    
    let rotateLabel = specify(Button(icon: "v", size: 20)) {
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
            $0.centerX.equalTo(emojiLabel.snp_leading)
            $0.centerY.equalTo(emojiLabel.snp_top)
        })
        self.add(rotateLabel, {
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
        drawRect = CGRect(origin: (-size.width/2) ^ (-size.height/2), size: size)
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
