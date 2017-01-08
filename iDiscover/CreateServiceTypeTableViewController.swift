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
  
  static func newController() -> CreateServiceTypeTableViewController {
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! CreateServiceTypeTableViewController
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var fullTypeLabel: UILabel!
  @IBOutlet weak var detailTextField: UITextField!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Create a Service"
    
    self.nameTextField.delegate = self
    self.typeTextField.delegate = self
    self.detailTextField.delegate = self
    
    self.resetForm()
  }
  
  // MARK: - Content
  
  func resetForm() {
    self.nameTextField.text = ""
    self.typeTextField.text = ""
    self.fullTypeLabel.text = "(REQUIRED)"
    self.detailTextField.text = nil
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 3 || indexPath.row == 4 {
      return super.tableView(tableView, heightForRowAt: indexPath) + 10
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == 0 {
      self.nameTextField.becomeFirstResponder()
    } else if indexPath.section == 1 {
      self.typeTextField.becomeFirstResponder()
    } else if indexPath.section == 2 {
      self.detailTextField.becomeFirstResponder()
      
    } else if indexPath.section == 3 && indexPath.row == 0 {
      self.createButtonSelected()
    } else if indexPath.section == 4 && indexPath.row == 0{
      self.clearButtonSelected()
    }
  }
  
  // MARK: - UITextFieldDelegate
  
  @IBAction func textFieldEditingChanged(_ sender: UITextField) {
    if sender == self.typeTextField {
      // Update the helper label
      if let type = self.typeTextField.text, !type.isEmpty {
        self.fullTypeLabel.text = "(_\(type)._tcp)"
      } else {
        self.fullTypeLabel.text = "(REQUIRED)"
      }
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
  
  private func createButtonSelected() {
    
    // Validate the form
    guard let name = self.nameTextField.text, !name.trim().isEmpty else {
      self.showDisappearingAlertDialog(title: "Service Name Required")
      return
    }
    
    guard let type = self.typeTextField.text, !type.trim().isEmpty else {
      self.showDisappearingAlertDialog(title: "Service Type Required")
      return
    }
    
    // Check that type does not match existing service types
    if MyServiceType.exists(type: type) {
      self.showDisappearingAlertDialog(title: "Invalid Type", message: "The entered service type \(type) is already taken.")
      return
    }
    
    var detail: String? = nil
    if let text = self.detailTextField.text, !text.trim().isEmpty {
      detail = text.trim()
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
  
  private func clearButtonSelected() {
    self.resetForm()
  }
}
