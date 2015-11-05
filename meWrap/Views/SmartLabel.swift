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
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    
    func setup() {
        self.userInteractionEnabled = true
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.PhoneNumber.rawValue | NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.text!, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
        linkContainer.appendContentsOf(results)
//                let mutableText = NSMutableAttributedString(attributedString: self.attributedText!)
//                for result in results {
//                    mutableText.addAttributes([NSForegroundColorAttributeName : self.tintColor], range: result.range)
//                }
//                self.attributedText = mutableText
    }
    
    func rectFlipped (rect : CGRect, bounds : CGRect) -> CGRect {
        return CGRectMake(CGRectGetMinX(rect),
            CGRectGetMaxY(bounds)-CGRectGetMaxY(rect),
            CGRectGetWidth(rect),
            CGRectGetHeight(rect));
    }
    
    func typographicBoundsAsRect(line : CTLine , lineOrigin : CGPoint) -> CGRect {
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading));
        let height = ascent + descent;
        
        return CGRectMake(lineOrigin.x,lineOrigin.y - descent, width, height)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
//        let framesetter = CTFramesetterCreateWithAttributedString(self.attributedText!)
//        var drawingRect = self.bounds
//        let sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0, 0), nil, CGSizeMake(drawingRect.size.width,CGFloat.max), nil)
//        let delta = max(0 , ceil(sz.height - drawingRect.size.height)) + 10
//        drawingRect.origin.y -= delta
//        drawingRect.size.height += delta
//        drawingRect.origin.y -= (drawingRect.size.height - sz.height)/2
//        
//        let path = CGPathCreateMutable()
//        CGPathAddRect(path, nil, drawingRect)
//        let textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, nil)
//        
//        let kVMargin : CGFloat = 5.0
//        let lines = CTFrameGetLines(textFrame)
//        
//        let nbLines = CFArrayGetCount(lines)
//
//        var originsArray = [CGPoint](count:nbLines, repeatedValue: CGPointZero)
//        CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), &originsArray)
//        
//        for lineIndex in  0..<nbLines {
//            let lineOriginFlipped = originsArray[lineIndex]
//            
//            let line: UnsafePointer<Void>? = CFArrayGetValueAtIndex(lines, 0)
//            let _line = unsafeBitCast(line!, AnyObject.self)
//            let lineRectFlipped = typographicBoundsAsRect(_line as! CTLine, lineOrigin: lineOriginFlipped)
//            var lineRect = rectFlipped(lineRectFlipped, bounds: rectFlipped(drawingRect, bounds: self.bounds))
//            lineRect = CGRectInset(lineRect, 0, -kVMargin);
//            if (CGRectContainsPoint(lineRect, point))
//            {
//                print (">>self - \(lineRect)- \(lineRectFlipped)<<")
//                let relativePoint = CGPointMake(point.x-CGRectGetMinX(lineRect),
//                    point.y-CGRectGetMinY(lineRect))
//                var idx = CTLineGetStringIndexForPosition(_line as! CTLine, relativePoint)
//                if ((relativePoint.x < CTLineGetOffsetForStringIndex(_line as! CTLine, idx, nil)) && (idx>0)) {
//                    --idx;
//                    
//                }
//                for checkingResult in linkContainer {
//                    if  (NSLocationInRange(idx, checkingResult.range)) {
//                        print (">>self - \(idx)<<")
//                    }
//                }
//                
//            }
//            
//        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(self.attributedText!)
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
    
                    let runAttributes = CTRunGetAttributes(_finalRuns)
                    let font = CFDictionaryGetValue(runAttributes, unsafeAddressOf(kCTFontAttributeName))
                    let _font = unsafeBitCast(font, AnyObject.self) as! CTFont
                    
                    let string = (self.attributedText?.string)! as NSString
                    var glyphs = Array<CGGlyph>(count: (self.attributedText?.string.characters.count)!, repeatedValue: 0)
                    var chars = Array<UniChar>(count: checkingRestult.range.length, repeatedValue: 0)
                    string.getCharacters(&chars, range: checkingRestult.range)
                    CTFontGetGlyphsForCharacters(_font, &chars, &glyphs, chars.count)
                    var glyphBounds = [CGRect](count:1, repeatedValue: CGRectZero)
                    CTFontGetBoundingRectsForGlyphs(_font, .Default , &glyphs, &glyphBounds, 1)
                    var idx = CTLineGetStringIndexForPosition(_line as! CTLine, point)
                    var offset = CTLineGetOffsetForStringIndex(_line as! CTLine, idx, nil)
                    
                    let finalLine = CFArrayGetValueAtIndex(lines, CFIndex(counter))
                    let _finalLine = unsafeBitCast(finalLine, AnyObject.self) as! CTLine
                    let lineBounds = CTLineGetBoundsWithOptions(_finalLine, [.IncludeLanguageExtents])
                    let finalRect = CGRectMake(lineBounds.origin.x, CGFloat(counter) * lineBounds.height, lineBounds.width, lineBounds.height)
                     print (">>self \(offset)<<")
                    if (CGRectContainsPoint(finalRect, point)) {
                        print("Great!!!")
                    }
                }
            }
        }
        
        
//        var glyphPosition: CGPoint = CGPointZero
//        
//       
//        
//        let lastGlyphIdx = CTRunGetGlyphCount(_finalRuns) - 1;
//        
//        CTRunGetPositions(_finalRuns, CFRangeMake(lastGlyphIdx, 1), &glyphPosition)
//        
//        var glyphBounds = [CGRect](count:1, repeatedValue: CGRectZero)
//        let runAttributes = CTRunGetAttributes(_finalRuns)
//        let font = CFDictionaryGetValue(runAttributes, unsafeAddressOf(kCTFontAttributeName))
//        let _font = unsafeBitCast(font, AnyObject.self) as! CTFont
//        let string = (self.attributedText?.string)! as NSString
//       
//        var glyphs = Array<CGGlyph>(count: (self.attributedText?.string.characters.count)!, repeatedValue: 0)
//        var chars = [UniChar]()
//        for checkingRestult in linkContainer {
//            var chars = Array<CGGlyph>(count: checkingRestult.range.length , repeatedValue: 0)
//            string.getCharacters(&chars, range: checkingRestult.range)
//             print (">>self - \(chars)<<")
//        }
//        
//       
//        for index in 25..<30 {
//            
//            chars.append(((self.attributedText?.string)! as NSString).characterAtIndex(index))
//            
//        }
//        let gotGlyphs = CTFontGetGlyphsForCharacters(_font, &chars, &glyphs, chars.count)
////        CTRunGetGlyphs(_finalRuns, CFRangeMake(lastGlyphIdx, 1), &glyph)
//        CTFontGetBoundingRectsForGlyphs(_font, .Default , &glyphs[25], &glyphBounds, 1)
//        
//        let finalLine = CFArrayGetValueAtIndex(lines, finalLineIdx)
//        let _finalLine = unsafeBitCast(finalLine, AnyObject.self) as! CTLine
//        let lineBounds = CTLineGetBoundsWithOptions(_finalLine, [.IncludeLanguageExtents])
//        
//        let desiredRect = CGRectMake(
//            CGRectGetMinX(self.bounds) + finalLineOrigin[0].x + glyphPosition.x + CGRectGetMinX(glyphBounds[0]),
//            CGRectGetMinY(self.bounds) + (CGRectGetHeight(self.bounds) - (finalLineOrigin[0].y + CGRectGetMaxY(lineBounds))),
//            CGRectGetWidth(glyphBounds[0]),
//            CGRectGetHeight(lineBounds)
//        )
   
    
        
        
        return true
    }
    
    
}
