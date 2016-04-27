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

enum TextOverlayType {
    case Sticker, Text
}

class TextOverlayView: UIView, KeyboardNotifying {
    
    lazy var contentView: UIView = specify(UIView()) { view in
        view.backgroundColor = UIColor.clearColor()
    }
    
    var transformView = TransformView() {
        willSet {
            insertSubview(newValue, aboveSubview: contentView)
            newValue.snp_makeConstraints {
                $0.centerX.equalTo(contentView.snp_leading)
                $0.centerY.equalTo(contentView.snp_top)
            }
            newValue.transform = CGAffineTransformMakeTranslation(contentView.width/2, contentView.height/2)
            newValue.trashLabel.addTarget(self, action: #selector(self.cancel(_:)), forControlEvents: .TouchUpInside)
            let rotatingGesture = UIPanGestureRecognizer(target: self, action: #selector(self.rotating(_:)))
            newValue.rotateLabel.addGestureRecognizer(rotatingGesture)
            let panningGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panning(_:)))
            panningGesture.minimumNumberOfTouches = 1
            newValue.addGestureRecognizer(panningGesture)
            panningGesture.requireGestureRecognizerToFail(rotatingGesture)
            let multiplePanningGesture = UIPanGestureRecognizer(target: self, action: #selector(self.multiplePanning(_:)))
            multiplePanningGesture.minimumNumberOfTouches = 2
            newValue.addGestureRecognizer(multiplePanningGesture)
        }
    }
    var close: (TextOverlay? -> Void)?
    
    let cancelButton = Button(icon: "!", size: 20, textColor: UIColor.whiteColor())
    let applyButton = Button(icon: "E", size: 24, textColor: UIColor.whiteColor())
    
    class func show(view: UIView, canvas: DrawingCanvas, type: TextOverlayType = .Sticker, close: (TextOverlay? -> Void)) -> TextOverlayView {
        let overlayView = TextOverlayView(frame: view.bounds)
        view.add(overlayView)
        overlayView.close = close
        overlayView.setup(canvas, type: type)
        return overlayView
    }
    
    func setup(canvas: DrawingCanvas, type: TextOverlayType = .Sticker) {
        contentView.frame = canvas.frame
        add(contentView) { (make) in
            make.edges.equalTo(canvas)
        }
        
        cancelButton.addTarget(self, touchUpInside: #selector(self.cancel(_:)))
        add(cancelButton) { $0.leading.top.equalTo(self).inset(20) }
        applyButton.addTarget(self, touchUpInside: #selector(self.apply(_:)))
        add(applyButton) { $0.trailing.top.equalTo(self).inset(20) }
        
        if type == .Sticker {
            FullScreenEmojiView.show(selectedBlock: { [weak self] emoji in
                self?.emojiSelected(emoji)
                }, close: { [weak self] in
                    self?.finishWithOverlay(nil)
                })
        } else {
            addTextEditableView()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.textFocus(_:)))
            addGestureRecognizer(tapGesture)
            Keyboard.keyboard.addReceiver(self)
        }
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
        
        let center = contentView.convertPoint(transformView.textView.center, fromCoordinateSpace: transformView)
        
        let d1 = p2.distanceFrom(center)
        let d2 = p1.distanceFrom(center)
        
        let angle = p1.angle(p2, center: center)
        
        transformView.transform = CGAffineTransformRotate(transformView.transform, angle)
        
        transformView.fontSize *= abs(d1/d2)
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
    
    func textFocus(sender: UIPanGestureRecognizer) {
        
        if transformView.textView.isFirstResponder() {
            transformView.textView.resignFirstResponder()
            transformView.textView.editable = false
            transformView.textView.selectable = false
            transformView.textView.userInteractionEnabled = false
        }
    }
    
    func emojiSelected(emoji: String) {
        transformView = StickerView()
        transformView.textView.text = emoji
        transformView.fontSize = min(contentView.width, contentView.height) / 3
    }
    
    func addTextEditableView() {
        transformView = TextEditableView()
        Dispatch.mainQueue.async { () in
            self.transformView.textView.becomeFirstResponder()
        }
    }
    
    private func finishWithOverlay(overlay: TextOverlay?) {
        transformView.textView.resignFirstResponder()
        close?(overlay)
        self.removeFromSuperview()
    }
    
    @objc private func apply(sender: UITapGestureRecognizer) {
        finishWithOverlay(TextOverlay(transformView: transformView))
    }
    
    @objc private func cancel(sender: UITapGestureRecognizer) {
        finishWithOverlay(nil)
    }
    
    func keyboardWillShow(keyboard: Keyboard) {
        guard let superview = self.superview else { return }
        let transform = superview.transform
        superview.transform = CGAffineTransformIdentity
        let center = convertPoint(transformView.textView.center, fromCoordinateSpace: transformView)
        let translation: CGFloat = (height - keyboard.height) / 2 - center.y
        superview.transform = transform
        keyboard.performAnimation { () in
            superview.transform = CGAffineTransformMakeTranslation(0, translation)
            cancelButton.transform = CGAffineTransformMakeTranslation(0, -translation)
            applyButton.transform = CGAffineTransformMakeTranslation(0, -translation)
        }
    }
    
    func keyboardWillHide(keyboard: Keyboard) {
        guard let superview = self.superview else { return }
        keyboard.performAnimation { () in
            superview.transform = CGAffineTransformIdentity
            cancelButton.transform = CGAffineTransformIdentity
            applyButton.transform = CGAffineTransformIdentity
        }
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
    
    var textView = specify(UITextView() , {
        $0.scrollEnabled = false
        $0.textContainerInset = UIEdgeInsetsZero
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
        layout()
    }
    
    func layout() {}
    
    var minFontSize: CGFloat = 40
    
    var fontSize: CGFloat {
        get {
            return textView.font!.pointSize
        }
        set {
            if textView.text.isEmpty == false {
                textView.font = textView.font!.fontWithSize(max(minFontSize, round(newValue)))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StickerView: TransformView {
    
    override func layout() {
        textView.userInteractionEnabled = false
        self.add(textView, {
            $0.edges.equalTo(self).inset(20)
            $0.width.equalTo(textView.snp_height)
        })
        self.add(trashLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(textView.snp_leading)
            $0.centerY.equalTo(textView.snp_top)
        })
        self.add(rotateLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(textView.snp_trailing)
            $0.centerY.equalTo(textView.snp_bottom)
        })
    }
}

class TextEditableView: TransformView, UITextViewDelegate {
    
    private let placeholder = "enter_text_here".ls
    
    override func layout() {
        textView.font = UIFont.systemFontOfSize(50)
        minFontSize = 7
        textView.textColor = UIColor.whiteColor()
        textView.text = placeholder
        textView.delegate = self
        self.add(textView, {
            $0.edges.equalTo(self).inset(20)
            $0.width.greaterThanOrEqualTo(60)
        })
        self.add(trashLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(textView.snp_leading)
            $0.centerY.equalTo(textView.snp_top)
        })
        self.add(rotateLabel, {
            $0.size.equalTo(40)
            $0.centerX.equalTo(textView.snp_trailing)
            $0.centerY.equalTo(textView.snp_bottom)
        })
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.textFocus(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView.text == placeholder {
            if !text.isEmpty {
                textView.text = text
            }
        } else {
            let result = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
            if result.isEmpty {
                textView.text = placeholder
            } else {
                textView.text = result
            }
        }
        return false
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if textView.text == placeholder {
            textView.selectedRange = NSMakeRange(textView.text.characters.count, 0)
        }
    }
    
    func textFocus(sender: UIPanGestureRecognizer) {
        
        if !textView.isFirstResponder() {
            textView.editable = true
            textView.selectable = true
            textView.userInteractionEnabled = true
            textView.becomeFirstResponder()
        }
    }
}

class TextOverlay: Drawing {
    
    let text: String
    let font: UIFont
    let transform: CGAffineTransform
    private let drawRect: CGRect
    private let attributes: [String : AnyObject]
    
    init(transformView: TransformView) {
        text = transformView.textView.text ?? ""
        font = transformView.textView.font!
        transform = transformView.transform
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = transformView.textView.textAlignment
        let textColor = transformView.textView.textColor ?? UIColor.whiteColor()
        attributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraph]
        let size = (text as NSString).sizeWithAttributes(attributes)
        drawRect = CGRect(origin: (-size.width/2) ^ (-size.height/2), size: size)
    }
    
    func render() {
        let rect = drawRect
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, rect.midX, rect.midY)
        CGContextConcatCTM(context, transform)
        CGContextTranslateCTM(context, -rect.midX, -rect.midY)
        (text as NSString).drawInRect(rect, withAttributes: attributes)
        CGContextRestoreGState(context)
    }
}
