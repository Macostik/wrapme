//: Playground - noun: a place where people can play

import UIKit

class DataSource : NSObject, UICollectionViewDataSource {
    var someString : String
    var someArray : Array<Int>
    
    init (str:String, array: Array<Int>) {
        someString = str
        someArray = array
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return someArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(someString, forIndexPath: indexPath)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
}

let object = DataSource(str: "someString", array: [1,3,5])