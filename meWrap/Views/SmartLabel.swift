//
//  SmartLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import MessageUI

struct CheckingType {
    let link: String!
    let result: NSTextCheckingResult!
    
    init (link: String, result: NSTextCheckingResult) {
        self.link = link
        self.result = result
    }
}

extension CheckingType: Hashable, Equatable {
    var hashValue: Int {
        return link.hashValue
    }
}

func ==(lhs: CheckingType, rhs: CheckingType) -> Bool {
    return lhs.link.hashValue == rhs.link.hashValue
}

let kPadding: CGFloat = 5.0

class SmartLabel : WLLabel, UIActionSheetDelegate, UIGestureRecognizerDelegate,  MFMessageComposeViewControllerDelegate {
  
    lazy var linkContainer = Set<CheckingType>()
    var bufferAttributedString: NSAttributedString?
    var _textColor: UIColor?
    var selectedLink: CheckingType?
    
    override var text: String? {
        get { return super.text }
        set {
            let wordRange = NSMakeRange(0, newValue!.characters.count)
            let attributedText = NSMutableAttributedString(string: newValue!)
            attributedText.addAttribute(NSForegroundColorAttributeName , value: _textColor!, range:wordRange)
            attributedText.addAttribute(NSFontAttributeName , value: self.font, range:wordRange)
            
            self.attributedText = attributedText
            checkingType()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        _textColor = textColor
        setup()
    }
    
    func setup () {
        self.userInteractionEnabled = true
        let longPress = UILongPressGestureRecognizer(target: self, action: "lognPress:")
        longPress.delegate = self
        addGestureRecognizer(longPress)
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.text!, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
        guard let _results: [NSTextCheckingResult] = results else {
            return
        }
        for result in _results {
            let link = (self.text! as NSString).substringWithRange(result.range)
            let checkingType = CheckingType(link: link, result: result)
            linkContainer.insert(checkingType)
        }
        
        let mutableText = NSMutableAttributedString(attributedString: self.attributedText!)
        for result in _results {
            mutableText.addAttributes([NSForegroundColorAttributeName : self.tintColor], range: result.range)
        }
        bufferAttributedString = self.attributedText
        self.attributedText = mutableText
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (gestureRecognizer is UILongPressGestureRecognizer && !self.linkContainer.isEmpty) {
            selectedLink = nil
            let point = touch.locationInView(self)
            let frameSetter = CTFramesetterCreateWithAttributedString(self.bufferAttributedString!)
            var drawRect = self.bounds
            drawRect.size.height += kPadding
            let drawingPath = CGPathCreateWithRect(drawRect, nil)
            let textFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, (self.attributedText?.string.characters.count)!), drawingPath, nil)
            let lines = CTFrameGetLines(textFrame)
            let linesCount = CFArrayGetCount(lines)
            for var counter : Int = 0; counter < linesCount; counter++ {
                let line = CFArrayGetValueAtIndex(lines, counter)
                let evaluateLine = unsafeBitCast(line, CTLineRef.self)
                let runs = CTLineGetGlyphRuns(evaluateLine)
                let finalRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1)
                let _finalRuns = unsafeBitCast(finalRun, CTRun.self)
                let runRange = CTRunGetStringRange(_finalRuns)
                let _runRange = NSMakeRange(runRange.location, runRange.length)

                for checkingResult in self.linkContainer {
                    let compareRange = NSIntersectionRange(_runRange, checkingResult.result.range)
                    if  (compareRange.length > 0)  {
                        let originX = CTLineGetOffsetForStringIndex(evaluateLine, checkingResult.result.range.location, nil)
                        let offsetX = CTLineGetOffsetForStringIndex(evaluateLine, checkingResult.result.range.location + checkingResult.result.range.length, nil)
                        let finalLine = CFArrayGetValueAtIndex(lines, CFIndex(counter))
                        let _finalLine = unsafeBitCast(finalLine, CTLineRef.self)
                        let lineBounds = CTLineGetBoundsWithOptions(_finalLine, [.IncludeLanguageExtents])
                        let finalRect = CGRectMake(originX, CGFloat(counter) * lineBounds.height, offsetX, lineBounds.height)
                        if (CGRectContainsPoint(finalRect, point)) {
                            selectedLink = checkingResult
                            return true
                        }
                    }
                }
            }
            return false
        }
        return false
    }
    
    func lognPress(sender: UILongPressGestureRecognizer) {
        if  sender.state == .Began {
            if  (selectedLink!.result.resultType == .Link) {
                let urlString = "http://" + selectedLink!.link
                if (urlString.isValidUrl()) {
                    let url = NSURL(string: urlString)
                    UIApplication.sharedApplication().openURL(url!);
                } else if (selectedLink!.link.isValidEmail()) {
                    if (MFMessageComposeViewController.canSendText()) {
                        let messageComposeVC = MFMessageComposeViewController()
                        messageComposeVC.messageComposeDelegate = self
                        messageComposeVC.recipients = [selectedLink!.link]
                        UIWindow.mainWindow().rootViewController?.presentViewController(messageComposeVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    //MARK: MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
