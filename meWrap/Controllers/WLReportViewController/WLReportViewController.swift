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
    let title:String
    let fontSize:CGFloat
    let fontColor:UIColor
    let isShowArrow:Bool
    init(title:String, fontSize:CGFloat, fontColor:UIColor, isShowArrow:Bool) {
        self.title = title
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.isShowArrow = isShowArrow
    }
}

struct ReportDataModel {
    let entries:[Entry] = []
    
    func pathFromFile(fileName:String) -> String? {
        return NSBundle.mainBundle().pathForResource(fileName, ofType: "plist")
    }
    
    func parse (fileName : String) -> [Entry] {
        var container:[Entry] = []
        let path = Optional.Some(fileName).flatMap(pathFromFile)
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
                let isShowArrow : Bool = dict["showArrow"] as! Bool
                
                let entry = Entry(title: title, fontSize: fontSize, fontColor: fontColor, isShowArrow: isShowArrow)
                container.append(entry)
            }
        }
        
        return container
    }
}

class WLReportViewController : UIViewController {
    weak var wrap:AnyObject?
    private var reportList:NSArray?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dataSource : WLCVDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let contentData = ReportDataModel()
        let reportList = contentData.parse("WLReportList")
        
        do {
           try dataSource.configuration(reportList)
        } catch ErrorHandler.Identifier {
            print("identifier is'n correct")
        } catch ErrorHandler.EmptyData {
            print("data is empty")
        } catch _ {
             print("something went wrong")
        }
    }
}
