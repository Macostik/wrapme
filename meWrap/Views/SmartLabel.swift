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
    let link: String
    let result: NSTextCheckingResult
}

extension CheckingType: Hashable {
    var hashValue: Int {
        return link.hashValue
    }
}

func ==(lhs: CheckingType, rhs: CheckingType) -> Bool {
    return lhs.link.hashValue == rhs.link.hashValue
}

let kPadding: CGFloat = 5.0

final class SmartLabel: Label, UIGestureRecognizerDelegate,  MFMailComposeViewControllerDelegate {
  
    private lazy var links = [NSTextCheckingResult]()
    private var bufferAttributedString: NSAttributedString?
    private var _textColor: UIColor?
    private var selectedLink: NSTextCheckingResult?
    private var tapGesture: UITapGestureRecognizer?
    private var longPress: UILongPressGestureRecognizer?
    
    private static let linkDetector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
    
    private static var cachedLinks: [String:[NSTextCheckingResult]] = {
        let cachedLinks = [String:[NSTextCheckingResult]]()
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: nil, usingBlock: { (_) -> Void in
            SmartLabel.cachedLinks.removeAll()
        })
        return cachedLinks
    }()
    
    private func cachedLinks(text: String) -> [NSTextCheckingResult] {
        if let links = SmartLabel.cachedLinks[text] {
            return links
        } else {
            let links = SmartLabel.linkDetector.matchesInString(text, options: [], range: NSMakeRange(0, text.characters.count))
            SmartLabel.cachedLinks[text] = links
            return links
        }
    }
    
    override var text: String? {
        get {
            return super.text
        }
        set {
            if let text = newValue {
                links = cachedLinks(text)
                if !links.isEmpty {
                    let attributedText = NSMutableAttributedString(string: text, attributes: [NSForegroundColorAttributeName : _textColor!, NSFontAttributeName : font])
                    bufferAttributedString = attributedText
                    for result in links {
                        attributedText.addAttributes([NSForegroundColorAttributeName : tintColor], range: result.range)
                    }
                    self.attributedText = attributedText
                } else {
                    attributedText = nil
                    super.text = text
                }
            } else {
                if attributedText != nil {
                    attributedText = nil
                }
                super.text = nil
            }
        }
    }
    
    override var textColor: UIColor! {
        willSet {
            _textColor = newValue
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SmartLabel.tapLink(_:)))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SmartLabel.longPress(_:)))
        self.tapGesture = tapGesture
        self.longPress = longPress
        tapGesture.delegate = self
        longPress.delegate = self
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(longPress)
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture || gestureRecognizer == longPress {
            if links.isEmpty { return false }
            selectedLink = nil
            let point = gestureRecognizer.locationInView(self)
            return isLinkedPoint(point)
        }
        return true
    }
    
    func isLinkedPoint(point: CGPoint) -> Bool  {
        let frameSetter = CTFramesetterCreateWithAttributedString(self.bufferAttributedString!)
        var drawRect = bounds
        drawRect.size.height += kPadding
        let drawingPath = CGPathCreateWithRect(drawRect, nil)
        guard let count = self.attributedText?.string.characters.count else { return false }
        let textFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, count), drawingPath, nil)
        let lines = CTFrameGetLines(textFrame)
        let linesCount = CFArrayGetCount(lines)
        for counter: Int in 0 ..< linesCount {
            let line = CFArrayGetValueAtIndex(lines, counter)
            let evaluateLine = unsafeBitCast(line, CTLineRef.self)
            let runs = CTLineGetGlyphRuns(evaluateLine)
            let finalRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1)
            let _finalRuns = unsafeBitCast(finalRun, CTRun.self)
            let runRange = CTRunGetStringRange(_finalRuns)
            let _runRange = NSMakeRange(runRange.location, runRange.length)
            for link in links {
                let compareRange = NSIntersectionRange(_runRange, link.range)
                if  (compareRange.length > 0)  {
                    let originX = CTLineGetOffsetForStringIndex(evaluateLine, link.range.location, nil)
                    let offsetX = CTLineGetOffsetForStringIndex(evaluateLine, link.range.location + link.range.length, nil)
                    let finalLine = CFArrayGetValueAtIndex(lines, CFIndex(counter))
                    let _finalLine = unsafeBitCast(finalLine, CTLineRef.self)
                    let lineBounds = CTLineGetBoundsWithOptions(_finalLine, [.IncludeLanguageExtents])
                    let finalRect = CGRectMake(originX, CGFloat(counter) * lineBounds.height, offsetX, lineBounds.height)
                    if (CGRectContainsPoint(finalRect, point)) {
                        selectedLink = link
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func tapLink(sender: UITapGestureRecognizer) {
        if let link = selectedLink, let text = text {
            let link = (text as NSString).substringWithRange(link.range)
            if link.isValidEmail {
                sendMessage(link)
            } else if let url = validUrl(link) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }
    
    func longPress(sender: UILongPressGestureRecognizer) {
        if (sender.state == .Began) {
            guard let link = selectedLink, let text = text else { return }
            let _link = (text as NSString).substringWithRange(link.range)
            guard let url = validUrl(_link) else { return }
            
            let actionSheet = UIAlertController.actionSheet(_link)
            actionSheet.action("cancel".ls, style: .Cancel)
            actionSheet.action("copy".ls, handler: { (action) -> Void in
                UIPasteboard.generalPasteboard().string = _link
            })
            
            let urlHandler: UIAlertAction -> Void = { (action) -> Void in
                UIApplication.sharedApplication().openURL(url)
            }
            
            if _link.isValidEmail {
                actionSheet.action("send_message".ls, handler: urlHandler)
            } else {
                actionSheet.action("url_open_in_safari".ls, handler: urlHandler)
                actionSheet.action("url_add_to_reading_list".ls, handler: { (action) -> Void in
                    _ = try? SSReadingList.defaultReadingList()?.addReadingListItemWithURL(url, title: nil, previewText: nil)
                })
            }
            actionSheet.show(self)
        }
    }
    
    func sendMessage(link: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setToRecipients([link])
            UINavigationController.main()?.presentViewController(mailComposeVC, animated: true, completion: nil)
        }
    }
    
    func validUrl(link: String) -> NSURL? {
        var _link = link
        if _link.rangeOfString("http(s)?://", options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) == nil {
            _link = "http://" + _link
        }
        return NSURL(string: _link)
    }
    
    //MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
