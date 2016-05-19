//
//  EntryView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/17/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class WrapView: UIView {
    
    private let cover = ImageView(backgroundColor: UIColor.clearColor())
    
    private let name = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
    
    let selectButton = Button(type: .Custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layout()
    }
    
    func layout() {
        cover.defaultIconSize = 16
        cover.defaultIconText = "t"
        cover.defaultBackgroundColor = Color.grayLighter
        cover.cornerRadius = 17
        add(cover) { (make) in
            make.size.equalTo(34)
            make.centerY.leading.equalTo(self)
        }
        
        name.highlightedTextColor = Color.grayLighter
        add(name) { (make) in
            make.leading.equalTo(cover.snp_trailing).offset(8)
            make.centerY.equalTo(self)
        }
        
        let arrow = Label(icon: "|", size: 17, textColor: UIColor.whiteColor())
        arrow.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        arrow.highlightedTextColor = Color.grayLighter
        add(arrow) { (make) in
            make.leading.equalTo(name.snp_trailing).offset(8)
            make.trailing.centerY.equalTo(self)
        }
        
        selectButton.highlightings = [name, arrow]
        add(selectButton) { (make) in
            make.edges.equalTo(self)
        }
        
        Wrap.notifier().addReceiver(self)
    }
    
    weak var wrap: Wrap? {
        didSet {
            if let wrap = wrap {
                setup(wrap)
            }
        }
    }
    
    func setup(wrap: Wrap) {
        cover.url = wrap.asset?.small
        name.text = wrap.name
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if let wrap = wrap {
            setup(wrap)
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap === entry
    }
}