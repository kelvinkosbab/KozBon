//
//  SettingsViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> SettingsViewController {
    return self.newViewController(fromStoryboard: .info)
  }
  
  // MARK: - Edit Mode Properties
  
  override var defaultViewTitle: String? {
    return "Information"
  }
  
  // MARK: - UICollectionView Helpers
  
  enum SettingsSectionType {
    case serviceTypes, other
    
    var sectionTitle: String {
      switch self {
      case .serviceTypes:
        return "Bonjour Services"
      case .other:
        return "Other"
      }
    }
    
    var items: [SettingsItemType] {
      switch self {
      case .serviceTypes:
        return [ .serviceTypeFullList, .serviceTypeCreate ]
      case .other:
        return [ .appVersion, .appDeveloper, .appWebsite, .appContact ]
      }
    }
    
    static let all: [SettingsSectionType] = [ .serviceTypes, .other ]
  }
  
  enum SettingsItemType {
    case serviceTypeFullList, serviceTypeCreate
    case appVersion, appDeveloper, appWebsite, appContact
    
    var title: String {
      switch self {
      case .serviceTypeFullList:
        return "Full List of Service Types"
      case .serviceTypeCreate:
        return "Create a Custom Service Type"
      default:
        return ""
      }
    }
    
    var key: String {
      switch self {
      case .appVersion:
        return "Version"
      case .appDeveloper:
        return "Developer"
      case .appWebsite:
        return "Website"
      case .appContact:
        return "Contact"
      default:
        return ""
      }
    }
    
    var value: String {
      switch self {
      case .appVersion:
        // Set the version label
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
          return "\(version) (\(build))"
        } else {
          return "Unable to retrieve ☹️"
        }
      case .appDeveloper:
        return "Kozinga"
      case .appWebsite:
        return "kozinga.net"
      case .appContact:
        return "kelvin.kosbab@kozinga.net"
      default:
        return ""
      }
    }
  }
  
  // MARK: - UICollectionView
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return SettingsSectionType.all.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
      
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SettingsHeaderView.name, for: indexPath) as! SettingsHeaderView
      let sectionType = SettingsSectionType.all[indexPath.section]
      headerView.configure(title: sectionType.sectionTitle)
      return headerView
      
    case UICollectionElementKindSectionFooter:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SettingsFooterView.name, for: indexPath) as! SettingsFooterView
      return headerView
      
    default:
      return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionType = SettingsSectionType.all[section]
    return sectionType.items.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch indexPath.section {
      
    case 0:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsItemCell.name, for: indexPath) as! SettingsItemCell
      let sectionType = SettingsSectionType.all[indexPath.section]
      let item = sectionType.items[indexPath.row]
      cell.configure(title: item.title)
      return cell
      
    case 1:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsKeyValueCell.name, for: indexPath) as! SettingsKeyValueCell
      let sectionType = SettingsSectionType.all[indexPath.section]
      let item = sectionType.items[indexPath.row]
      cell.configure(key: item.key, value: item.value)
      return cell
      
    default:
      return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let sectionType = SettingsSectionType.all[indexPath.section]
    let item = sectionType.items[indexPath.row]
    switch item {
      
    case .serviceTypeFullList:
      let viewController = AllServiceTypesTableViewController.newViewController()
      viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
      
    case .serviceTypeCreate:
      let viewController = CreateServiceTypeTableViewController.newViewController()
      viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
      
    case .appWebsite:
      let path = "http://kozinga.net/"
      UIPasteboard.general.string = path
      self.showDisappearingAlertDialog(title: "Website Copied", message: "\(path) copied to the clipboard.")
      
    case .appContact:
      let email = "kelvin.kosbab@kozinga.net"
      UIPasteboard.general.string = email
      self.showDisappearingAlertDialog(title: "Email Copied", message: "\(email) copied to the clipboard.")
      
    default: break
    }
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 0)
  }
}
