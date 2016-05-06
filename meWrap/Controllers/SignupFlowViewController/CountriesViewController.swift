//
//  CountriesViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/4/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class CountryCell: EntryStreamReusableView<Country> {
    
    private let countryNameLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDark)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
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
    
    override func setup(country: Country) {
        countryNameLabel.text = country.name
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
    
    private let streamView = StreamView()
    
    private lazy var dataSource: StreamDataSource<[Country]> = StreamDataSource(streamView: self.streamView)
    
    override func loadView() {
        super.loadView()
        let navigationBar = UIView()
        navigationBar.backgroundColor = UIColor.whiteColor()
        self.navigationBar = view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        navigationBar.add(backButton(Color.orange)) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: Color.orange)
        title.text = "select_your_country".ls
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        view.add(streamView) { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let metrics = dataSource.addMetrics(StreamMetrics<CountryCell>(size: 50))
        metrics.selection = { [weak self] view in
            view.item?.selected = true
            if let country = view.entry {
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
