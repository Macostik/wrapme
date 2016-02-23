//
//  WLReportViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//



import Foundation
import UIKit

class ViolationCell : UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var showArrowLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var leadingContstraint: NSLayoutConstraint!
    
    var select : ((ViolationCell, Violation) -> Void)?
    var entry : Violation? {
        didSet {
            guard let entry = entry else {
                return
            }
            textLabel.text = entry.title?.ls
            textLabel.textColor = entry.fontColor
            textLabel.font = textLabel.font.fontWithSize(entry.fontSize)
            showArrowLabel.hidden = entry.code == nil
            button.hidden = showArrowLabel.hidden
            leadingContstraint.constant += entry.indent
        }
    }
    
    @IBAction func postViolationRequest(sender: AnyObject) {
        if let entry = entry where entry.code != nil {
            select?(self, entry)
        }
    }
}

class CVDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var data : [Violation] = []
    var select : ((ViolationCell, Violation) -> Void)?
    
    @IBInspectable var identifier: String = ""
    @IBInspectable var cellWidth: CGFloat = 0
    @IBInspectable var cellHeight: CGFloat = 0
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let entry = data[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! ViolationCell
        cell.entry = entry
        cell.select = select
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(cellWidth > 0 ? cellWidth : UIScreen.mainScreen().bounds.width, cellHeight > 0 ? cellHeight : 50)
    }
}

struct Violation {
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
        if let content = NSArray.plist("violations") as? [[String : AnyObject]] {
            return content.map({ (dict) -> Violation in
                return Violation(attribute: dict)
            })
        } else {
            return []
        }
    }
}

class ReportViewController : WLBaseViewController {
    
    weak var candy: Candy?
    
    private var reportList:NSArray?
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dataSource : CVDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.hidden = true
        let violations = Violation.allViolations()
        dataSource.select = { [weak self] _ , violation in
            guard let candy = self?.candy else {
                return
            }
            if let request = APIRequest.reportCandy(candy, violation: violation) {
                request.send({[weak self] (_) -> Void in
                    self?.collectionView.hidden = true
                    self?.doneButton.hidden = false
                    }, failure: { (error) -> Void in
                        error?.show()
                })
            } else {
                self?.collectionView.hidden = true
                self?.doneButton.hidden = false
            }
        }
        dataSource.data = violations
        collectionView.reloadData()
    }
    
    @IBAction func done() {
        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(false)
        } else {
            presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}
