//
//  WrapNameViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 6/29/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

final class WrapNameViewController: BaseViewController, UITextFieldDelegate {
    
    let textField = TextField()
    
    let nextButton = Button(type: .Custom)
    
    let backgroundImageView = UIImageView()
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    
    lazy var backButton: Button = self.backButton(UIColor.whiteColor())
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.grayDarker
        backgroundImageView.contentMode = .ScaleAspectFill
        view.add(backgroundImageView) { (make) in
            make.edges.equalTo(view)
        }
        view.add(blurView) { $0.edges.equalTo(view) }
        
        nextButton.hidden = true
        let topView = UIView()
        topView.backgroundColor = Color.grayDarker
        view.add(topView) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(115)
        }
        
        topView.add(backButton) { (make) in
            make.leading.equalTo(topView).offset(12)
            make.centerY.equalTo(topView.snp_top).offset(42)
        }
        nextButton.makeWizardButton(with: "next".ls)
        
        nextButton.addTarget(self, touchUpInside: #selector(self.next(_:)))
        topView.add(nextButton) { (make) in
            make.trailing.equalTo(topView).offset(-12)
            make.centerY.equalTo(backButton)
        }
        
        let titleLabel = Label(preset: .Large, weight: .Semibold, textColor: UIColor.whiteColor())
        titleLabel.text = "name_your_wrap".ls
        topView.add(titleLabel) { (make) in
            make.leading.equalTo(backButton.snp_trailing).offset(12)
            make.centerY.equalTo(backButton)
            make.trailing.lessThanOrEqualTo(nextButton.snp_leading).offset(-12)
        }
        
        textField.returnKeyType = .Done
        textField.textColor = UIColor.whiteColor()
        textField.font = UIFont.fontLarge()
        textField.makePresetable(.Large)
        textField.attributedPlaceholder = NSAttributedString(string: "type_wrap_name".ls, attributes: [NSForegroundColorAttributeName: Color.grayLighter, NSFontAttributeName: UIFont.lightFontNormal()])
        textField.delegate = self
        textField.strokeColor = UIColor.whiteColor()
        textField.highlightedStrokeColor = Color.orange
        textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        textField.rightViewMode = .WhileEditing
        topView.add(textField) { (make) in
            make.leading.equalTo(backButton.snp_trailing)
            make.centerX.equalTo(view)
            make.centerY.equalTo(topView.snp_bottom).offset(-32)
            make.height.equalTo(32)
        }
    }
    
    @objc private func next(sender: AnyObject) {
        completionHandler?(textField.text?.trim ?? "")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    var completionHandler: (String -> ())?
    
    @objc internal func textFieldDidChange(textField: TextField) {
        var text = textField.text?.trim ?? ""
        if text.characters.count > Constants.wrapNameLimit {
            text = text.substringToIndex(text.startIndex.advancedBy(Constants.wrapNameLimit))
            textField.text = text
        }
        nextButton.hidden = text.isEmpty
    }
}