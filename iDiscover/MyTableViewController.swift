//
//  MyTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyTableViewController: UITableViewController {
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - UITableView
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 40
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 30
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
}
