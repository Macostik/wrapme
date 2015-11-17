//
//  WLReportViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//



import Foundation
import UIKit

class ReportCell : UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var showArrowLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var leadingContstraint: NSLayoutConstraint!
    
    var select : ((ReportCell, String) -> Void)?
    var entry : ReportItem? {
        didSet {
            guard let entry = entry else {
                return
            }
            textLabel.text = entry.title
            textLabel.textColor = entry.fontColor
            textLabel.font = textLabel.font.fontWithSize(entry.fontSize ?? 0)
            showArrowLabel.hidden = entry.v_code == nil
            button.hidden = showArrowLabel.hidden
            leadingContstraint.constant += entry.indent ?? 0
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    @IBAction func postViolationRequest(sender: AnyObject) {
        if let entry = entry, let v_code = entry.v_code {
            select?(self, v_code)
        }
    }
}

class CVDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var data : [ReportItem] = []
    var select : ((ReportCell, String) -> Void)?
    
    @IBInspectable var identifier: String = ""
    @IBInspectable var cellWidth: CGFloat = 0
    @IBInspectable var cellHeight: CGFloat = 0
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let entry = data[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! ReportCell
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

enum InformationError: ErrorType {
    case MissingError(String)
    case InvalidError(String)
}

struct ReportItem {
    let title: String?
    let fontSize: CGFloat?
    var fontColor: UIColor?
    let v_code: String?
    let indent: CGFloat?
    
    init?(attribute:Dictionary<String, AnyObject>) throws {
        
        title = attribute["title"] as? String
        fontSize = attribute["fontSize"] as? CGFloat

        if let color = attribute["fontColor"] as? Array<CGFloat> {
            fontColor = UIColor(red: CGFloat (color[0])/255, green: CGFloat(color[1])/255, blue: CGFloat (color[2])/255, alpha: CGFloat(color[3]))
        }
        
        v_code = attribute["v_code"] as? String
        indent = attribute["indent"] as? CGFloat
    }
    
    static func items(fileName : String) -> [ReportItem] {
        var container:[ReportItem] = []
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist")
        if  let path = path {
            let content = NSArray(contentsOfFile:path)! as Array
            guard !content.isEmpty else  {
                return []
            }
            for dict in content {
                do {
                    let entry = try ReportItem(attribute: dict as! Dictionary<String, AnyObject>)
                    container.append(entry!)
                } catch InformationError.MissingError(let description) {
                    print("\(description)")
                } catch InformationError.InvalidError(let description) {
                    print("\(description)")
                } catch {
                    print("Initialization is wrong")
                }
            }
        }
        
        return container
    }
}

class ReportViewController : WLBaseViewController {
    weak var candy:AnyObject?
    private var reportList:NSArray?
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dataSource : CVDataSource!
    
    var reportClosure: ((String, ReportViewController) -> (Void))?
    
    var doneClosure: ((Void) -> (Void))?
    
    func reportingFinished() {
        collectionView.hidden = true
        doneButton.hidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.hidden = true
        let reportList = ReportItem.items("WLReportList")
        dataSource.select = {[unowned self] _ , violationCode in
            if let reportClosure = self.reportClosure {
                reportClosure(violationCode, self)
            }
        }
        dataSource.data = reportList
        collectionView.reloadData()
    }
    
    @IBAction func done() {
        if let doneClosure = self.doneClosure {
            doneClosure()
        } else if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(false)
        } else if let presentingViewController = presentingViewController {
            presentingViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}
