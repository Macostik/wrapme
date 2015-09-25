//
//  WLCollectionViewDataSource.swift
//  meWrap
//
//  Created by Yura Granchenko on 23/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

enum ErrorHandler : ErrorType {
    case Identifier
    case EmptyData
    
    func descreption() -> String {
        switch self {
        case .Identifier: return "Identifier is'n correct"
        case .EmptyData : return "Data is empty"
        }
    }
}

@objc class WLCVDataSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var data : [Entry] = []
    
    @IBInspectable var identifier: String = ""
    @IBInspectable var cellWidth: CGFloat = 0
    @IBInspectable var cellHeight: CGFloat = 0
    
    
    override init () {
        super.init()
    }
    
    func configuration (data:[Entry]) throws {
        guard !identifier.isEmpty else {
            throw ErrorHandler.Identifier
        }
        guard !data.isEmpty else {
            throw ErrorHandler.EmptyData
        }
        self.data = data
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let entry = data[indexPath.item] as Entry
        let cell : WLReportCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! WLReportCell
        cell.entry = entry
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
     func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(cellWidth > 0 ? cellWidth : UIScreen.mainScreen().bounds.width, cellHeight > 0 ? cellHeight : 50)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let entry = data[indexPath.item] as Entry
        if entry.isShowArrow {
            collectionView.hidden = true
        }
    }
    
}