//
//  PublishDetailCreateViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishDetailCreateViewController: MyTableViewController, UITextFieldDelegate {
  
  // MARK: - Class Accessors
  
  static func newController() -> PublishDetailCreateViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! PublishDetailCreateViewController
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var fullTypeLabel: UILabel!
  @IBOutlet weak var portTextField: UITextField!
  @IBOutlet weak var domainTextField: UITextField!
  @IBOutlet weak var detailTextField: UITextField!
  @IBOutlet weak var publishButton: UIButton!
  @IBOutlet weak var clearButton: UIButton!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Create a Service"
    
    self.nameTextField.delegate = self
    self.typeTextField.delegate = self
    self.portTextField.delegate = self
    self.domainTextField.delegate = self
    self.detailTextField.delegate = self
    
    self.resetForm()
  }
  
  // MARK: - Content
  
  func resetForm() {
    self.nameTextField.text = ""
    self.typeTextField.text = ""
    self.fullTypeLabel.text = "(REQUIRED)"
    self.portTextField.text = "3000"
    self.domainTextField.text = ""
    self.detailTextField.text = nil
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 5 || indexPath.row == 6 {
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
      self.portTextField.becomeFirstResponder()
    } else if indexPath.section == 3 {
      self.domainTextField.becomeFirstResponder()
    } else if indexPath.section == 4 {
      self.detailTextField.becomeFirstResponder()
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
    if textField == self.typeTextField && !string.containsWhitespace {
      return false
    } else if textField == self.domainTextField && !string.containsWhitespace {
      return false
    } else if textField == self.portTextField && !string.containsDecimalDigits {
      return false
    }
    return true
  }
  
  // MARK: - Actions
  
  @IBAction func publishButtonSelected(_ sender: UIButton) {
    
    // Validate the form
    guard let name = self.nameTextField.text, !name.trim().isEmpty else {
      self.showAlertDialog(title: "Service Name Required")
      return
    }
    
    guard let type = self.typeTextField.text, !type.trim().isEmpty else {
      self.showAlertDialog(title: "Service Type Required")
      return
    }
    
    guard let port = self.portTextField.text, let portValue = port.convertToInt, portValue > 0 else {
      self.showAlertDialog(title: "Invalid Port Number")
      return
    }
    
    let domain = self.domainTextField.text ?? ""
    var detail: String? = nil
    if let text = self.detailTextField.text, !text.trim().isEmpty {
      detail = text.trim()
    }
    
    // Publish the service
    MyLoadingManager.showLoading()
    MyBonjourPublishManager.shared.publish(name: name, type: type, port: portValue, domain: domain, transportLayer: .tcp, detail: detail, success: {
      // Success
      MyLoadingManager.hideLoading()
      self.showAlertDialog(title: "Service Published!") {
        self.dismissController(completion: {
          NotificationCenter.default.post(name: .publishNetServiceSearchShouldDismiss, object: nil)
        })
      }
    }) { 
      // Failure
      MyLoadingManager.hideLoading()
      self.showAlertDialog(title: "☹️ Something Went Wrong ☹️", message: "Please try again.")
    }
  }
  
  @IBAction func clearButtonSelected(_ sender: UIButton) {
    self.resetForm()
  }
  
  private func showAlertDialog(title: String, message: String? = nil, okSelected: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
      okSelected?()
    }))
    self.present(alertController, animated: true, completion: nil)
  }
}
