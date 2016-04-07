//
//  WelcomeViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class WelcomeViewController: BaseViewController {
    
    @IBOutlet weak var licenseButton: UIButton!
    @IBOutlet weak var termsAndConditionsTextView: UITextView!
    @IBOutlet var transparentView: UIView!
    @IBOutlet var placeholderView: UIView!
    
    override func loadView() {
        super.loadView()
        
        if !Environment.isProduction {
            let environmentButton = UIButton(type: .Custom)
            environmentButton.setTitle("Environment: \(Environment.current.name)", forState: .Normal)
            environmentButton.addTarget(self, action: #selector(WelcomeViewController.changeEnvironment(_:)), forControlEvents: .TouchUpInside)
            view.addSubview(environmentButton)
            environmentButton.snp_makeConstraints(closure: { (make) -> Void in
                make.centerX.equalTo(view)
                make.top.equalTo(view).offset(42)
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        underlineLicenseButton()
        termsAndConditionsTextView.tapped { [weak self] _ in
            self?.setTermsAndConditionsHidden(true)
        }
    }
 
    private func underlineLicenseButton() {
        let title = NSMutableAttributedString(string:"terms_and_conditions".ls)
        let range = NSMakeRange(0, title.length)
        title.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
        title.addAttribute(NSFontAttributeName, value: UIFont.fontSmall(), range: range)
        title.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: range)
        licenseButton.setAttributedTitle(title, forState: .Normal)
    }

    @IBAction func termsAndConditions(sender: AnyObject) {
        termsAndConditionsTextView.attributedText = getTermsAndConditions()
        setTermsAndConditionsHidden(false)
    }
    
    private func setTermsAndConditionsHidden(hidden: Bool) {
        let fromView = hidden ? placeholderView : transparentView
        let toView = hidden ? transparentView : placeholderView
        let option: UIViewAnimationOptions = hidden ? .TransitionFlipFromRight : .TransitionFlipFromLeft
        UIView.transitionFromView(fromView, toView: toView, duration: 0.75, options: [option, .ShowHideTransitionViews], completion: nil)
    }
    
    private func getTermsAndConditions() -> NSAttributedString? {
        guard let url = NSBundle.mainBundle().URLForResource("terms_and_conditions", withExtension: "rtf") else { return nil }
        let options = [NSObject:AnyObject]()
        return try? NSAttributedString(fileURL: url, options: options, documentAttributes: nil)
    }

    @IBAction func agreeAndContinue(sender: AnyObject) {
        if let introduction = UIStoryboard.introduction.instantiateInitialViewController() {
            navigationController?.setViewControllers([introduction], animated: false)
        }
    }
    
    @IBAction func changeEnvironment(sender: AnyObject) {
        let actioSheet = UIAlertController.actionSheet("Change environment")
        for name in Environment.names {
            actioSheet.action(name, handler: { _ in
                NSUserDefaults.standardUserDefaults().environment = name
                InfoToast.show("Please, relaunch the app.")
            })
        }
        actioSheet.action("Cancel", style: .Cancel)
        actioSheet.show()
    }
}

extension WelcomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(otherGestureRecognizer is UILongPressGestureRecognizer)
    }
}
