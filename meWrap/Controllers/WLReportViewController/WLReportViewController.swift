//
//  WLReportViewController.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//



import Foundation
import UIKit

enum InformationError: ErrorType {
    case MissingError(String)
    case InvalidError(String)
}

struct Entry {
    let title: String
    let fontSize: CGFloat
    let fontColor: UIColor
    let v_code: String
    let indent: CGFloat
    init?(attribute:Dictionary<String, AnyObject>) throws {
        
        guard let title = attribute["title"] as? String else { throw InformationError.MissingError("Incorrect title") }
        guard let fontSize = attribute["fontSize"] as? CGFloat else { throw InformationError.MissingError("Incorrect fontSize") }
        guard let fontColorList = attribute["fontColor"] else { throw InformationError.MissingError("Incorrect color")  }
        
        guard   let red  = (fontColorList[0] as? NSNumber),
                let green = (fontColorList[1] as? NSNumber),
                let blue = (fontColorList[2] as? NSNumber),
                let alpha = (fontColorList[3]as? NSNumber) else { throw InformationError.InvalidError("Invalid color value") }
        
        let fontColor = UIColor(red: CGFloat (red)/255,
                                green: CGFloat(green)/255,
                                blue: CGFloat (blue)/255,
                                alpha: CGFloat(alpha))
        
        let v_code = (attribute["v_code"] as? String) ?? ""
        guard let indent = attribute["indent"] as? CGFloat else { throw InformationError.MissingError("Incorrect indent") }
        
        self.title = title
        self.fontSize = fontSize
        self.fontColor  = fontColor
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
            for dict in content {
                do {
                    let entry = try Entry(attribute: dict as! Dictionary<String, AnyObject>)
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
