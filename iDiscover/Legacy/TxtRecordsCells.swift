//
//  TxtRecordsCells.swift
//  TxtRecordsCells
//
//  Created by Kelvin Kosbab on 7/15/21.
//  Copyright © 2021 Kozinga. All rights reserved.
//

import UIKit

// MARK: - TxtRecordCell

class TxtRecordCell: UITableViewCell {
    
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
}

// MARK: - AddTxtRecordCell

class AddTxtRecordCell: UITableViewCell {
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    @IBAction func addButtonPressed() {
        
    }
}
