//
//  SmartLabel.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension CATextLayer {
    convenience init(frame: CGRect, string: NSAttributedString) {
        self.init();
        self.contentsScale = UIScreen.mainScreen().scale;
        self.frame = frame;
        self.string = string;
    }
}

class SmartLabel : UILabel, NSLayoutManagerDelegate {
  
    let textStorage = NSTextStorage(string: " ");
    let textContainer = NSTextContainer();
    let layoutManager = NSLayoutManager();
    var characterTextLayers = Array<CATextLayer>()
    var linkContainer = [NSString:UInt64]()
    
    override var lineBreakMode: NSLineBreakMode {
        get { return super.lineBreakMode }
        set {
            textContainer.lineBreakMode = newValue
            super.lineBreakMode = newValue
        }
    }
    
    override var numberOfLines: Int {
        get { return super.numberOfLines }
        set {
            textContainer.maximumNumberOfLines = newValue
            super.numberOfLines = newValue
        }
        
    }
    
    override var bounds: CGRect {
        get { return super.bounds }
        set {
            textContainer.size = newValue.size
            super.bounds = newValue
        }
    }
    
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
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
            if textStorage.string == self.attributedText!.string {
                return
            }
//            self.sizeToFit()
//            textContainer.size = bounds.size
            textStorage.setAttributedString(self.attributedText!)
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

    func setup () {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        layoutManager.delegate = self
        self.userInteractionEnabled = true
    }
    
    func layoutManager(layoutManager: NSLayoutManager, didCompleteLayoutForTextContainer textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
            self.checkingType()
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.PhoneNumber.rawValue | NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.textStorage.string, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
//        calculateTextLayers()
        let mutableAttributedText = NSMutableAttributedString(string: self.textStorage.string)
        for result in results {
            let range = result.range
            mutableAttributedText.setAttributes([NSForegroundColorAttributeName:self.tintColor], range:range)
             print("range - \(range)")
            calculateTextLayers(range)
           
            
//            self.layoutManager.enumerateEnclosingRectsForGlyphRange(range, withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), inTextContainer: textContainer, usingBlock: { (rect, flag) -> Void i,n
//                if  (rect.origin.y != 0) {
//                    self.linkContainer[NSStringFromCGRect(rect)] = result.resultType.rawValue
//                    print("\(rect.origin.x), \(rect.origin.y), \(rect.size.width), \(rect.size.height)")
//                }
//            })
            
        }
        self.attributedText = NSAttributedString(attributedString:mutableAttributedText as! NSAttributedString)
    }
    
    func calculateTextLayers(range: NSRange) {
        characterTextLayers.removeAll(keepCapacity: false)
        let attributedText = textStorage.string
        
        let wordRange = range;
        let attributedString = self.internalAttributedText();
        let layoutRect = layoutManager.usedRectForTextContainer(textContainer);
        
        for var index = wordRange.location; index < wordRange.length+wordRange.location; index += 0 {
            let glyphRange = NSMakeRange(index, 1);
            let characterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange:nil);
            let textContainer = layoutManager.textContainerForGlyphAtIndex(index, effectiveRange: nil);
            var glyphRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer!);
            let location = layoutManager.locationForGlyphAtIndex(index);
            let kerningRange = layoutManager.rangeOfNominallySpacedGlyphsContainingIndex(index);
            
            print("range - \(range)")
            print("glyphRange - \(glyphRange)")
            print("characterRange -  \(characterRange)")
            print("textContainer - \(textContainer)")
            print(  "glyphRect - \(glyphRect) " )
            print( "location - \(location) " )
            print("kerningRange - \(kerningRange)")
            if kerningRange.length > 1 && kerningRange.location == index {
                if characterTextLayers.count > 0 {
                    let previousLayer = characterTextLayers[characterTextLayers.endIndex-1]
                    var frame = previousLayer.frame
                    frame.size.width += CGRectGetMaxX(glyphRect)-CGRectGetMaxX(frame)
                    previousLayer.frame = frame
                }
            }
            
            
            glyphRect.origin.y += location.y-(glyphRect.height/2)+(self.bounds.size.height/2)-(layoutRect.size.height/2);
            
            
            let textLayer = CATextLayer(frame: glyphRect, string: attributedString.attributedSubstringFromRange(characterRange));
//            initialTextLayerAttributes(textLayer)
            
//            layer.addSublayer(textLayer);
            characterTextLayers.append(textLayer);
            
            index++;
        }
    }
    
    func internalAttributedText() -> NSMutableAttributedString! {
        let wordRange = NSMakeRange(0, textStorage.string.characters.count);
        let attributedText = NSMutableAttributedString(string: textStorage.string);
        attributedText.addAttribute(NSForegroundColorAttributeName , value: self.textColor.CGColor, range:wordRange);
        attributedText.addAttribute(NSFontAttributeName , value: self.font, range:wordRange);
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = self.textAlignment
        attributedText.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range: wordRange)
        
        return attributedText;
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for (rectString, link) in self.linkContainer {
            let frame = CGRectFromString(rectString as String)
            if frame.contains(point) {
                
            }
            print("rect - \(frame) and point - \(point)")
        }
        return false;
    }
}



