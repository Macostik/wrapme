//
//  SmartLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class SmartLabel : UILabel {
  
    var linkContainer = [NSTextCheckingResult]()
    var bufferAttributedString : NSAttributedString?
    
    override var text: String! {
        get { return super.text }
        set {
            let wordRange = NSMakeRange(0, newValue.characters.count)
            let attributedText = NSMutableAttributedString(string: newValue)
            attributedText.addAttribute(NSForegroundColorAttributeName , value:self.textColor, range:wordRange)
            attributedText.addAttribute(NSFontAttributeName , value:self.font, range:wordRange)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = self.textAlignment
            attributedText.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range: wordRange)
            
            self.attributedText = attributedText
            checkingType()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userInteractionEnabled = true
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.PhoneNumber.rawValue | NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.text!, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
        linkContainer.appendContentsOf(results)
        let mutableText = NSMutableAttributedString(attributedString: self.attributedText!)
        for result in results {
            mutableText.addAttributes([NSForegroundColorAttributeName : self.tintColor], range: result.range)
        }
        bufferAttributedString = self.attributedText
        self.attributedText = mutableText
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let framesetter = CTFramesetterCreateWithAttributedString(bufferAttributedString!)
        let drawingPath = CGPathCreateWithRect(self.bounds, nil)
        let textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, (self.attributedText?.string.characters.count)!), drawingPath, nil)
        
        let lines = CTFrameGetLines(textFrame)
        let linesCount = CFArrayGetCount(lines)
        for var counter : Int = 0; counter < linesCount; counter++ {
            let line = CFArrayGetValueAtIndex(lines, counter)
            let _line = unsafeBitCast(line, AnyObject.self) as! CTLine
            let runs = CTLineGetGlyphRuns(_line)
            let finalRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1)
            let _finalRuns = unsafeBitCast(finalRun, AnyObject.self) as! CTRun
            let runRange = CTRunGetStringRange(_finalRuns)
            let _runRange = NSMakeRange(runRange.location, runRange.length)
             for checkingRestult in linkContainer {
                let compareRange = NSIntersectionRange(_runRange, checkingRestult.range)
                if  (compareRange.location > 0 && compareRange.length > 0) {
                    
                    let originX = CTLineGetOffsetForStringIndex(_line, checkingRestult.range.location, nil)
                    let offsetX = CTLineGetOffsetForStringIndex(_line, checkingRestult.range.location + checkingRestult.range.length, nil)
                    
                    let finalLine = CFArrayGetValueAtIndex(lines, CFIndex(counter))
                    let _finalLine = unsafeBitCast(finalLine, AnyObject.self) as! CTLine
                    let lineBounds = CTLineGetBoundsWithOptions(_finalLine, [.IncludeLanguageExtents])
                    let finalRect = CGRectMake(originX, CGFloat(counter) * lineBounds.height, offsetX, lineBounds.height)
                    if (CGRectContainsPoint(finalRect, point)) {
                        if  (checkingRestult.resultType == .Link) {
                            let urlString = NSString(string: (bufferAttributedString?.string)!).substringWithRange(compareRange)
                            let url = NSURL(string: urlString)?.absoluteURL
                             UIApplication.sharedApplication().openURL(url!);
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    
}
