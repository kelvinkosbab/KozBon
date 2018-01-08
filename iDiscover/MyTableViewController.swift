//
//  MyTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyTableViewController : UITableViewController, PresentableController, MyViewControllerIdentifierProtocol {
  
  // MARK: - PresentableController
  
  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.backBarButtonItem = UIBarButtonItem(text: "")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Status Bar
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .white
    return headerView
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 15
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let footerView = UIView()
    footerView.backgroundColor = .clear
    return footerView
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
}
