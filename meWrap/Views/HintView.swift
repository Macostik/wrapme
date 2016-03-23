
final class HintView: GradientView {
    
    class func show(casheKey: String, inView view: UIView = UIWindow.mainWindow.rootViewController?.view ?? UIWindow.mainWindow) {
        let hintView = HintView()
        hintView.show(casheKey, inView: view)
    }
    
    func show(casheKey: String, inView view: UIView) {
        var shownHints = NSUserDefaults.standardUserDefaults().shownHints
        if shownHints[casheKey] == nil {
            shownHints[casheKey] = true
            NSUserDefaults.standardUserDefaults().shownHints = shownHints
        
            startColor = UIColor.blackColor().colorWithAlphaComponent(0.85)
            endColor = UIColor.blackColor()
            frame = view.frame
            view.addSubview(self)
            snp_makeConstraints(closure: { $0.edges.equalTo(view) })
            alpha = 0.0
            snp_makeConstraints(closure: { $0.edges.equalTo(view) })
            
            let label = Label(preset: .XLarge, weight: .Regular, textColor: Color.orange)
            label.text = "swipe_actions_tip".ls
            label.numberOfLines = 2
            label.textAlignment = .Center
            addSubview(label)
            label.snp_makeConstraints(closure: {
                $0.leading.greaterThanOrEqualTo(self).offset(36)
                $0.trailing.greaterThanOrEqualTo(self).offset(-36)
                $0.centerX.equalTo(self)
                $0.centerY.equalTo(self).dividedBy(2)})
            
            let topImageView = ImageView(image: UIImage(named:"goToChat"))
            addSubview(topImageView)
            topImageView.snp_makeConstraints(closure: {
                $0.top.equalTo(label).offset(70)
                $0.leading.trailing.equalTo(self)
                $0.height.equalTo(50)
            })
            
            let buttonImageView = ImageView(image: UIImage(named:"goToCamera"))
            addSubview(buttonImageView)
            buttonImageView.snp_makeConstraints(closure: {
                $0.top.equalTo(topImageView).offset(60)
                $0.leading.trailing.equalTo(self)
                $0.height.equalTo(50)
            })
            
            let button = Button(type: .Custom)
            button.backgroundColor = Color.orange
            button.normalColor = UIColor.whiteColor()
            button.preset = FontPreset.Small.rawValue
            button.backgroundColor = Color.orange
            button.cornerRadius = 5
            button.titleLabel?.font = UIFont.fontSmall()
            button.setTitle("got_it".ls , forState: .Normal)
            button.addTarget(self, action: #selector(HintView.hide(_:)), forControlEvents: .TouchUpInside)
            self.addSubview(button)
            button.snp_makeConstraints(closure: {
                $0.trailing.equalTo(-12)
                $0.bottom.equalTo(-75)
                $0.width.equalTo(95)
            })
            
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .CurveEaseIn , animations: {
                self.alpha = 1.0
                }, completion: nil)
        }
    }
    
    func hide(sender: Button) {
        UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .CurveEaseIn, animations: { _ in
            self.alpha = 0.0
            }) { _ in
                self.removeFromSuperview()
        }
    }
}

extension HintView {
    class func showHomeSwipeTransitionHintView(view: UIView) {
        show("HomeSwipeTransitionView", inView: view)
    }
}