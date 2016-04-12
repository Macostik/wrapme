//
//  CountriesViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class CountryCell: StreamReusableView {
    
    private let countryNameLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDark)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        addSubview(countryNameLabel)
        let separator = SeparatorView(color: Color.grayLightest)
        addSubview(separator)
        countryNameLabel.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self).offset(10)
            make.centerY.equalTo(self)
        }
        separator.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.left.right.bottom.equalTo(self)
        }
    }
    
    override func setup(entry: AnyObject?) {
        if let country = entry as? Country {
            countryNameLabel.text = country.name
        }
    }
    
    override var selected: Bool {
        didSet {
            backgroundColor = selected ? UIColor(white:0.9, alpha:1) : UIColor.whiteColor()
        }
    }
}

class CountriesViewController: BaseViewController {
    
    var selectedCountry: Country?
    
    var selectionBlock: (Country -> Void)?
    
    @IBOutlet weak var streamView: StreamView!
    
    private lazy var dataSource: StreamDataSource<[Country]> = StreamDataSource(streamView: self.streamView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let metrics = dataSource.addMetrics(StreamMetrics(loader: StreamLoader<CountryCell>(), size: 50))
        metrics.selection = { [weak self] item, entry in
            item?.selected = true
            if let country = entry as? Country {
                self?.selectionBlock?(country)
            }
        }
        
        dataSource.didLayoutItemBlock = { [weak self] item in
            if let country = item.entry as? Country where country.code == self?.selectedCountry?.code {
                item.selected = true
            }
        }
        
        Dispatch.defaultQueue.fetch({ return Country.allCountries }) { [weak self] (object) -> Void in
            self?.dataSource.items = object
            self?.dataSource.streamView?.scrollToItem(self?.dataSource.streamView?.selectedItem, animated: false)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
