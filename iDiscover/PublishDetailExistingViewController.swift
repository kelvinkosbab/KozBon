//
//  PublishDetailExistingViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishDetailExistingViewController: MyTableViewController, UITextFieldDelegate {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> PublishDetailExistingViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  static func newViewController(serviceType: MyServiceType) -> PublishDetailExistingViewController {
    let viewController = self.newViewController()
    viewController.serviceType = serviceType
    return viewController
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var transportLayerSegmentedControl: UISegmentedControl!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var fullTypeLabel: UILabel!
  @IBOutlet weak var portTextField: UITextField!
  @IBOutlet weak var domainTextField: UITextField!
  @IBOutlet weak var detailTextField: UITextField!
  
  weak var delegate: PublishNetServiceDelegate? = nil
  
  var serviceType: MyServiceType!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Publish", target: self, action: #selector(self.publishButtonSelected))
    
    self.nameTextField.isUserInteractionEnabled = false
    self.nameTextField.textColor = UIColor.darkGray
    self.typeTextField.isUserInteractionEnabled = false
    self.typeTextField.textColor = UIColor.darkGray
    self.fullTypeLabel.textColor = UIColor.darkGray
    self.portTextField.delegate = self
    self.domainTextField.delegate = self
    self.detailTextField.isUserInteractionEnabled = false
    self.detailTextField.textColor = UIColor.darkGray
    
    self.resetForm()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateServiceContent()
  }
  
  // MARK: - Content
  
  func resetForm() {
    self.updateServiceContent()
    self.portTextField.text = "3000"
    self.domainTextField.text = ""
  }
  
  // MARK: - Content
  
  func updateServiceContent() {
    self.title = self.serviceType.fullType
    self.transportLayerSegmentedControl.selectedSegmentIndex = self.serviceType.transportLayer.isTcp ? 0 : 1
    self.transportLayerSegmentedControl.isUserInteractionEnabled = false
    self.nameTextField.text = self.serviceType.name
    self.typeTextField.text = self.serviceType.type
    self.fullTypeLabel.text = "(\(self.serviceType.fullType))"
    if let detail = self.serviceType.detail, !detail.isEmpty {
      self.detailTextField.text = detail
    } else {
      self.detailTextField.text = "No additional information"
    }
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == 3 {
      self.portTextField.becomeFirstResponder()
    } else if indexPath.section == 4 {
      self.domainTextField.becomeFirstResponder()
      
    } else if indexPath.section == 6 && indexPath.row == 0 {
      self.clearButtonSelected()
    }
  }
  
  // MARK: - UITextFieldDelegate
  
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
    if textField == self.domainTextField && !string.containsWhitespace {
      return false
    } else if textField == self.portTextField && !string.containsDecimalDigits {
      return false
    }
    return true
  }
  
  // MARK: - Actions
  
  @objc func publishButtonSelected() {
    
    guard let port = self.portTextField.text, let portValue = port.convertToInt, portValue > 0 else {
      self.showDisappearingAlertDialog(title: "Invalid Port Number")
      return
    }
    
    let domain = self.domainTextField.text ?? ""
    
    // Publish the service
    MyLoadingManager.showLoading()
    MyBonjourPublishManager.shared.publish(name: self.serviceType.name, type: self.serviceType.type, port: portValue, domain: domain, transportLayer: self.serviceType.transportLayer, detail: self.serviceType.detail, success: {
      // Success
      MyLoadingManager.hideLoading()
      self.showDisappearingAlertDialog(title: "Service Published!") {
        self.dismissController(completion: {
          self.delegate?.servicePublished()
        })
      }
    }) {
      // Failure
      MyLoadingManager.hideLoading()
      self.showDisappearingAlertDialog(title: "☹️ Something Went Wrong ☹️", message: "Please try again.")
    }
  }
  
  private func clearButtonSelected() {
    self.resetForm()
  }
}
