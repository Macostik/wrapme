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
            print (">>self - \(newValue)<<")
            super.bounds = newValue
            textContainer.size = CGSizeMake(bounds.width, CGFloat.max)
            textStorage.setAttributedString(self.attributedText!)
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
        get { return super.attributedText }
        set {
            if textStorage.string == newValue!.string {
                return
            }
            super.attributedText = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayoutManager()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLayoutManager()
    }
    
    
    func setupLayoutManager() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        layoutManager.delegate = self
        textContainer.lineFragmentPadding = 0
        self.userInteractionEnabled = true
    }
    
    func layoutManager(layoutManager: NSLayoutManager, didCompleteLayoutForTextContainer textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        checkingType()
    }
    
    func checkingType() {
        let detector = try! NSDataDetector(types: NSTextCheckingType.PhoneNumber.rawValue | NSTextCheckingType.Link.rawValue)
        let results = detector.matchesInString(self.textStorage.string, options: .ReportProgress, range: NSMakeRange(0, self.text!.characters.count))
        let temp = results.flatMap({$0.range})
        print (">>self - \(temp)<<")
        setupTextLayers(temp)
        
    }
    
    func setupTextLayers(ranges: Array<NSRange>) {
        characterTextLayers.removeAll(keepCapacity: false)
        let attributedText = textStorage.string
        
        let wordRange = NSMakeRange(0, attributedText.characters.count);
        let layoutRect = layoutManager.usedRectForTextContainer(textContainer);
        
        for var index = wordRange.location; index < wordRange.length+wordRange.location; index += 0 {
            let glyphRange = NSMakeRange(index, 1);
            let characterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange:nil);
            let textContainer = layoutManager.textContainerForGlyphAtIndex(index, effectiveRange: nil);
            var glyphRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer!);
            let location = layoutManager.locationForGlyphAtIndex(index);
            let kerningRange = layoutManager.rangeOfNominallySpacedGlyphsContainingIndex(index);
            
            if kerningRange.length > 1 && kerningRange.location == index {
                if characterTextLayers.count > 0 {
                    let previousLayer = characterTextLayers[characterTextLayers.endIndex-1]
                    var frame = previousLayer.frame
                    frame.size.width += CGRectGetMaxX(glyphRect)-CGRectGetMaxX(frame)
                    previousLayer.frame = frame
                }
            }
            print("__________________________")
            print("glyphRect.begin - \(glyphRect)")
//            glyphRect.origin.y += location.y - (glyphRect.height/2)+(self.bounds.size.height/2)-(layoutRect.size.height/2);
            
            
            print (">>self -\(textStorage.attributedSubstringFromRange(characterRange).string)<<")
            print("glyphRange.end - \(glyphRange)")
            print("characterRange -  \(characterRange)")
            print("glyphRect - \(glyphRect) " )
            print("location - \(location) " )
            print("kerningRange - \(kerningRange)")
            print("layoutRect - \(layoutRect)")
            print("self.frame - \(self.frame)")
            print("--------------------------")
            
            let string = textStorage.attributedSubstringFromRange(characterRange).string
            let textLayer = initialTextLayer(string, frame: glyphRect)
            let passTextRange = ranges.filter({
                return $0.location <= index && $0.location + $0.length >= index
            })
             print ("\(index) - \(passTextRange)<<")
//            if  (ranges.location <= index && range.location + range.length >= index) {
//                print ("\(index) - \(range)<<")
//                textLayer.foregroundColor = tintColor.CGColor
//            }
            layer.addSublayer(textLayer)
            characterTextLayers.append(textLayer);
            
            index += characterRange.length;
        }
    }
    
    func initialTextLayer(string: String, frame: CGRect) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.frame = frame
        textLayer.string = string
        textLayer.foregroundColor = UIColor.orangeColor().CGColor
        textLayer.font = CTFontCreateWithName(font.fontName, font.lineHeight, nil);
        textLayer.fontSize = font.pointSize
        textLayer.wrapped = true
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.contentsScale = UIScreen.mainScreen().scale
        return textLayer
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



