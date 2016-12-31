//
//  SettingsTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/31/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class SettingsTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> SettingsTableViewController {
    return self.newController(fromStoryboard: .settings, withIdentifier: self.name) as! SettingsTableViewController
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var versionLabel: UILabel!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Settings"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Set the version label
    if let dictionary = Bundle.main.infoDictionary, let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String {
      self.versionLabel.text = "\(version) (\(build))"
    } else {
      self.versionLabel.text = "Unable to retrieve ☹️"
    }
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == 0 {
      if indexPath.row == 1 {
        // All service types
      } else if indexPath.row == 2 {
        // Created service types
      } else if indexPath.row == 3 {
        // Create a service type
      }
      
    } else if indexPath.section == 1 {
      // Support
      
      if indexPath.row == 3 {
        // Url
        let path = "http://kozinga.net/"
        UIPasteboard.general.string = path
        self.showAlertDialog(title: "URL Copied", message: "\(path) copied to the clipboard.")
        
      } else if indexPath.row == 4 {
        // Email
        let email = "kelvin.kosbab@kozinga.net"
        UIPasteboard.general.string = email
        self.showAlertDialog(title: "Email Copied", message: "\(email) copied to the clipboard.")
      }
    }
  }
  
  // MARK: - Helpers
  
  private func showAlertDialog(title: String, message: String? = nil) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    self.present(alertController, animated: true) {
      DispatchQueue.main.asyncAfter(after: 1.5) {
        self.dismiss(animated: true, completion: nil)
      }
    }
  }
}
