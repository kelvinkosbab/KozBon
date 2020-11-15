//
//  ServicesServiceCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServicesServiceCell : UICollectionViewCell {
    @IBOutlet weak private var containerView: UIView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    private var service: MyNetService? = nil
    private var isPublished: Bool = false
    
    func configure(service: MyNetService, isPublished: Bool) {
        self.isPublished = isPublished
        self.service = service
        self.titleLabel.text = service.serviceType.name
        if isPublished {
            self.detailLabel.text = "[Published] \(service.hostName)"
        } else {
            self.detailLabel.text = service.hostName
        }
        service.delegate = self
    }
    
    func configure(title: String?, detail: String?) {
        self.service = nil
        self.titleLabel.text = title
        self.detailLabel.text = detail
    }
}

// MARK: - MyNetServiceDelegate

extension ServicesServiceCell : MyNetServiceDelegate {
    
    func serviceDidResolveAddress(_ service: MyNetService) {
        self.configure(service: service, isPublished: self.isPublished)
    }
}
