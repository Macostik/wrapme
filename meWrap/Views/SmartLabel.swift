//
//  SmartLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import MessageUI
import SafariServices

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

class SmartLabel : WLLabel, UIGestureRecognizerDelegate,  MFMailComposeViewControllerDelegate {
  
    lazy var linkContainer = Set<CheckingType>()
    var bufferAttributedString: NSAttributedString?
    var _textColor: UIColor?
    var selectedLink: CheckingType?
    var tapGesture: UITapGestureRecognizer?
    var longPress: UILongPressGestureRecognizer?
    
    override var text: String? {
        get { return super.text }
        set {
            if let newValue: String = newValue {
                let wordRange = NSMakeRange(0, newValue.characters.count)
                let attributedText = NSMutableAttributedString(string: newValue)
                attributedText.addAttribute(NSForegroundColorAttributeName , value: _textColor!, range:wordRange)
                attributedText.addAttribute(NSFontAttributeName , value: self.font, range:wordRange)
                
                self.attributedText = attributedText
                checkingType()
            }
        }
    }
    
    override var textColor: UIColor! {
        get { return super.textColor }
        set {
            if let newValue: UIColor = newValue {
                _textColor = newValue
                self.layoutIfNeeded()
            }
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
        tapGesture = UITapGestureRecognizer(target: self, action: "tapLink:")
        longPress = UILongPressGestureRecognizer(target: self, action: "longPress:")
        guard let tapGesture: UITapGestureRecognizer = tapGesture, let longPress: UILongPressGestureRecognizer = longPress else { return }
        tapGesture.delegate = self
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(longPress)
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.text!, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
        guard let _results: [NSTextCheckingResult] = results else {
            return
        }
        linkContainer = Set<CheckingType>()
        for result in _results {
            if let link: String = (self.text! as NSString).substringWithRange(result.range) {
                if let checkingType: CheckingType = CheckingType(link: link, result: result) {
                    linkContainer.removeAll()
                    linkContainer.insert(checkingType)
                }
            }
        }
        
        let mutableText = NSMutableAttributedString(attributedString: self.attributedText!)
        for result in _results {
            mutableText.addAttributes([NSForegroundColorAttributeName : self.tintColor], range: result.range)
        }
        bufferAttributedString = self.attributedText
        self.attributedText = mutableText
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == tapGesture || gestureRecognizer == longPress) {
            if  (self.linkContainer.isEmpty) { return false }
            selectedLink = nil
            let point = gestureRecognizer.locationInView(self)
            return isLinkedPoint(point)
        }
        return true
    }
    
    func isLinkedPoint(point: CGPoint) -> Bool  {
        let frameSetter = CTFramesetterCreateWithAttributedString(self.bufferAttributedString!)
        var drawRect = self.bounds
        drawRect.size.height += kPadding
        let drawingPath = CGPathCreateWithRect(drawRect, nil)
        guard let count = self.attributedText?.string.characters.count else { return false }
        let textFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, count), drawingPath, nil)
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
                        if let checkingResult: CheckingType = checkingResult {
                            selectedLink = checkingResult
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func tapLink(sender: UITapGestureRecognizer) {
        if  (selectedLink?.result.resultType == .Link) {
            if let link = selectedLink?.link {
                if (link.isValidEmail) {
                   sendMessage(link)
                } else if let url = validUrl(link) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
    }
    
    func longPress(sender: UILongPressGestureRecognizer) {
        if (sender.state == .Began) {
            guard let link = selectedLink?.link else { return }
            guard let url = validUrl(link) else { return }
            let actionSheetController = UIAlertController(title: link, message: nil, preferredStyle: .ActionSheet)
            let cancelAction = UIAlertAction(title: "cancel".ls, style: .Cancel, handler: { (action) -> Void in
                actionSheetController.dismissViewControllerAnimated(true, completion: nil)
            })
            let copyAction = UIAlertAction(title: "copy".ls , style: .Default, handler: { (action) -> Void in
                UIPasteboard.generalPasteboard().string = link
            })
            
            let openInSafariAction = UIAlertAction(title: "url_open_in_safari".ls, style: .Default, handler: { (action) -> Void in
                UIApplication.sharedApplication().openURL(url);
            })
            
            let sendMessageAction = UIAlertAction(title: "send_message".ls, style: .Default, handler: { (action) -> Void in
                UIApplication.sharedApplication().openURL(url);
            })
        
            let addReadingListAction = UIAlertAction(title: "url_add_to_reading_list".ls, style: .Default, handler: { (action) -> Void in
                do {
                    try SSReadingList.defaultReadingList()?.addReadingListItemWithURL(url, title: nil, previewText: nil)
                } catch _ {}
            })
            
            actionSheetController.addAction(cancelAction)
            actionSheetController.addAction(copyAction)
            if (link.isValidEmail) {
                actionSheetController.addAction(sendMessageAction)
            } else {
                actionSheetController.addAction(openInSafariAction)
                actionSheetController.addAction(addReadingListAction)
            }
    
             UINavigationController.mainNavigationController()?.presentViewController(actionSheetController, animated: true, completion: nil)
        }
    }
    
    func sendMessage(link: String) {
        if (MFMailComposeViewController.canSendMail()) {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setToRecipients([link])
            UINavigationController.mainNavigationController()?.presentViewController(mailComposeVC, animated: true, completion: nil)
        }
    }
    
    func validUrl(var link: String) -> NSURL? {
        let schema = link.rangeOfString("http(s)?://", options: [.RegularExpressionSearch, .CaseInsensitiveSearch])
        if ((schema?.endIndex.predecessor()) == nil) {
            link = "http://" + link
        }
        
        return NSURL(string: link)
    }
    
    //MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
