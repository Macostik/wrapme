//
//  WLReportViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//



import Foundation
import UIKit

struct Entry {
    let title: String
    let fontSize: CGFloat
    let fontColor: UIColor
    let v_code: String
    let indent: CGFloat
    init(title:String, fontSize:CGFloat, fontColor:UIColor, v_code:String, indent:CGFloat) {
        self.title = title
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.v_code = v_code
        self.indent = indent
    }
}

struct ReportDataModel {
    let entries:[Entry] = []
    
    func parse (fileName : String) -> [Entry] {
        var container:[Entry] = []
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist")
        if  let path = path {
            let content = NSArray(contentsOfFile:path)! as Array
            guard !content.isEmpty else  {
                return []
            }
            for (_, dict)in content.enumerate() {
                let title : String = dict["title"] as! String
                let fontSize : CGFloat = dict["fontSize"] as! CGFloat
                let fontColorList = dict["fontColor"] as! [Int]
                let red = CGFloat(fontColorList[0])/255
                let green = CGFloat(fontColorList[1])/255
                let blue = CGFloat (fontColorList[2])/255
                let alpha = CGFloat (fontColorList[3])
                let fontColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
                let v_code : String = dict["v_code"] as? String ?? ""
                let indent : CGFloat = dict["indent"] as! CGFloat
                
                let entry = Entry(title: title, fontSize: fontSize, fontColor: fontColor, v_code: v_code, indent: indent)
                container.append(entry)
            }
        }
        
        return container
    }
}

class WLReportViewController : UIViewController {
    weak var candy:AnyObject?
    private var reportList:NSArray?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dataSource : WLCVDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let contentData = ReportDataModel()
        let reportList = contentData.parse("WLReportList")
        dataSource.select = {[unowned self] _ , violationCode in
            WLAPIRequest.postCandy(candy, violationCode: violationCode).send({
                _ in self.collectionView.hidden = true }, failure:{ _ in
            })
        }
        dataSource.data = reportList
    }
}
