//
//  ReportViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//



import Foundation
import UIKit

final class ViolationCell: EntryStreamReusableView<Violation> {
    
    private let textLabel = Label(preset: .Normal, weight: .Regular)
    private let arrow = Label(icon: "x", size: 17, textColor: Color.grayLighter)
    private let selectButton = Button(type: .Custom)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        selectButton.addTarget(self, touchUpInside: #selector(self.selectAction))
        selectButton.highlightedColor = Color.grayLightest
        add(selectButton) { (make) in
            make.edges.equalTo(self)
        }
        
        arrow.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        arrow.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        add(arrow) { (make) in
            make.trailing.equalTo(self).offset(-12)
            make.centerY.equalTo(self)
        }
        add(textLabel) { (make) in
            make.leading.equalTo(self).offset(12)
            make.centerY.equalTo(self)
            make.trailing.lessThanOrEqualTo(arrow.snp_leading).offset(-12)
        }
    }
    
    override func setup(violatin: Violation) {
        textLabel.text = violatin.title?.ls
        textLabel.textColor = violatin.fontColor
        textLabel.font = textLabel.font.fontWithSize(violatin.fontSize)
        arrow.hidden = violatin.code == nil
        selectButton.hidden = arrow.hidden
        textLabel.snp_updateConstraints { (make) in
            make.leading.equalTo(self).offset(12 + violatin.indent)
        }
    }
}

final class Violation {
    let title: String?
    let fontSize: CGFloat
    let fontColor: UIColor?
    let code: String?
    let indent: CGFloat
    
    init(attribute:[String : AnyObject]) {
        title = attribute["title"] as? String
        fontSize = (attribute["fontSize"] as? CGFloat) ?? 0
        code = attribute["v_code"] as? String
        indent = (attribute["indent"] as? CGFloat) ?? 0
        if let color = attribute["fontColor"] as? [CGFloat] {
            fontColor = UIColor(red: color[0]/255, green: color[1]/255, blue: color[2]/255, alpha: color[3])
        } else {
            fontColor = nil
        }
    }
    
    static func allViolations() -> [Violation] {
        let content = NSArray.plist("violations") as? [[String : AnyObject]]
        return content?.map({ Violation(attribute: $0) }) ?? []
    }
}

final class ReportViewController: BaseViewController {
    
    let candy: Candy
    
    required init(candy: Candy) {
        self.candy = candy
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let streamView = StreamView()
    private lazy var dataSource: StreamDataSource<[Violation]> = StreamDataSource(streamView: self.streamView)
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        let navigationBar = UIView()
        navigationBar.backgroundColor = Color.orange
        self.navigationBar = view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        let backButton = Button(icon: "w", size: 24, textColor: UIColor.whiteColor())
        backButton.setTitleColor(UIColor.whiteColor().darkerColor(), forState: .Highlighted)
        backButton.addTarget(self, action: #selector(self.done), forControlEvents: .TouchUpInside)
        navigationBar.add(backButton) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "Report"
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        self.navigationBar = navigationBar
        
        streamView.delaysContentTouches = false
        view.add(streamView) { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.addMetrics(StreamMetrics<ViolationCell>(size: 36)).selection = { [weak self] cell in
            guard let candy = self?.candy, let violation = cell.entry else { return }
            API.reportCandy(candy, violation: violation)?.send({ [weak self] (_) -> Void in
                self?.reportCompleted()
                }, failure: { (error) -> Void in
                    error?.show()
            })
        }
        dataSource.items = Violation.allViolations()
    }
    
    private func reportCompleted() {
        streamView.removeFromSuperview()
        let doneButton = Button(preset: .Normal, weight: .Regular, textColor: UIColor.whiteColor())
        doneButton.setTitle("done".ls, forState: .Normal)
        doneButton.addTarget(self, touchUpInside: #selector(self.done))
        navigationBar!.add(doneButton, { (make) in
            make.trailing.equalTo(navigationBar!).offset(-12)
            make.centerY.equalTo(navigationBar!).offset(10)
        })
        
        let thankYouLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDark)
        thankYouLabel.numberOfLines = 0
        thankYouLabel.text = "thank_you".ls
        view.add(thankYouLabel) { (make) in
            make.leading.equalTo(view).offset(12)
            make.top.equalTo(navigationBar!.snp_bottom).offset(12)
            make.trailing.lessThanOrEqualTo(view).offset(-12)
        }
        
        let thankYouLabel1 = Label(preset: .Small, weight: .Regular, textColor: Color.grayLighter)
        thankYouLabel1.numberOfLines = 0
        thankYouLabel1.text = "thank_you_for_report".ls
        view.add(thankYouLabel1) { (make) in
            make.leading.equalTo(view).offset(12)
            make.top.equalTo(thankYouLabel.snp_bottom).offset(12)
            make.trailing.lessThanOrEqualTo(view).offset(-12)
        }
    }
    
    @IBAction func done() {
        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(false)
        } else {
            presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}
