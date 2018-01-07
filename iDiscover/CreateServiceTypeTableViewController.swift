//
//  CreateServiceTypeTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/3/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class CreateServiceTypeTableViewController: MyTableViewController, UITextFieldDelegate {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> CreateServiceTypeTableViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var transportLayerSegmentedControl: UISegmentedControl!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var fullTypeLabel: UILabel!
  @IBOutlet weak var detailTextField: UITextField!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Create a Service"
    
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(text: "Cancel", target: self, action: #selector(self.cancelButtonSelected(_:)))
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Create", target: self, action: #selector(self.createButtonSelected(_:)))
    
    self.nameTextField.delegate = self
    self.typeTextField.delegate = self
    self.detailTextField.delegate = self
    
    self.resetForm()
  }
  
  // MARK: - Content
  
  func resetForm() {
    self.transportLayerSegmentedControl.selectedSegmentIndex = 0
    self.nameTextField.text = ""
    self.typeTextField.text = ""
    self.fullTypeLabel.text = "(REQUIRED)"
    self.detailTextField.text = nil
  }
  
  func updateTypeHelperLabel() {
    if let type = self.typeTextField.text, !type.isEmpty {
      self.fullTypeLabel.text = MyServiceType.generateFullType(type: type, transportLayer: self.selectedTransportLayer)
    } else {
      self.fullTypeLabel.text = "(REQUIRED)"
    }
  }
  
  // MARK: - Transport Layer Control
  
  @IBAction func transportLayerSegmentedControlValueChanged(_ sender: UISegmentedControl) {
    self.updateTypeHelperLabel()
  }
  
  var selectedTransportLayer: MyTransportLayer {
    return self.transportLayerSegmentedControl.selectedSegmentIndex == 0 ? .tcp : .udp
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == 1 {
      self.nameTextField.becomeFirstResponder()
    } else if indexPath.section == 2 {
      self.typeTextField.becomeFirstResponder()
    } else if indexPath.section == 3 {
      self.detailTextField.becomeFirstResponder()
      
    } else if indexPath.section == 4 && indexPath.row == 0 {
      self.resetForm()
    }
  }
  
  // MARK: - UITextFieldDelegate
  
  @IBAction func textFieldEditingChanged(_ sender: UITextField) {
    if sender == self.typeTextField {
      self.updateTypeHelperLabel()
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    
    // Check if delete key
    if string == "" && range.length > 0 {
      return true
    }
    
    // Character validations by text field
    if textField == self.typeTextField && !string.containsWhitespace && !string.contains("-") && !string.contains("_") && !string.containsAlphanumerics {
      return false
    }
    return true
  }
  
  // MARK: - Actions
  
  @objc func cancelButtonSelected(_ sender: UIButton) {
    self.dismissController()
  }
  
  @objc func createButtonSelected(_ sender: UIButton) {
    
    // Validate the form
    
    let transportLayer = MyTransportLayer.tcp
    
    guard let name = self.nameTextField.text?.trimmed, !name.isEmpty else {
      self.showDisappearingAlertDialog(title: "Service Name Required")
      return
    }
    
    guard let type = self.typeTextField.text?.trimmed, !type.isEmpty else {
      self.showDisappearingAlertDialog(title: "Service Type Required")
      return
    }
    
    // Check that type does not match existing service types
    if MyServiceType.exists(type: type, transportLayer: transportLayer) {
      self.showDisappearingAlertDialog(title: "Invalid \(transportLayer.string.uppercased()) Type", message: "The entered \(transportLayer.string.uppercased()) service type \(type) is already taken.")
      return
    }
    
    var detail: String? = nil
    if let text = self.detailTextField.text?.trimmed, !text.isEmpty {
      detail = text
    }
    
    // Create the service type
    let serviceType = MyServiceType(name: name, type: type, transportLayer: .tcp, detail: detail)
    
    // Save a persistent copy of the service type
    serviceType.savePersistentCopy()
    
    // Show alert dialog and dismiss
    self.showDisappearingAlertDialog(title: "Service Type Created!", message: "\(name) has been created!") { 
      self.dismissController()
      NotificationCenter.default.post(name: .myServiceTypeDidCreateAndSave, object: serviceType)
    }
  }
}
