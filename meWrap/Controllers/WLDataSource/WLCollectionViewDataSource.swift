//
//  WLCollectionViewDataSource.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

@objc class WLCVDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var data : [Entry] = []
    var select : ((WLReportCell, String) -> Void)?
    
    @IBInspectable var identifier: String = ""
    @IBInspectable var cellWidth: CGFloat = 0
    @IBInspectable var cellHeight: CGFloat = 0
    
    
    override init () {
        super.init()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let entry = data[indexPath.item] as Entry
        let cell : WLReportCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! WLReportCell
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